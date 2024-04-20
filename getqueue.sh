#!/bin/bash

clear

source tokenservice.sh

# calls for a new device list
# this is to compare the first device lists's 'lastDwTimestamp' parameter
# with this new one

send_new_check(){
    
    curl \
        -H "Authorization: Bearer $(token)" \
        -H "Accept: application/json" \
        -s --show-error --fail \
        "https://community.thingpark.io/thingpark/wireless/rest/subscriptions/mine/devices?name=$NAME_FILTER&healthState=ACTIVE" | jq \
        >> JSON_output/verbose_new.json

}

send_new_check

EUI_ARRAY=$(jq -r '.briefs[].EUI' JSON_output/verbose_new.json)
IFS=$'\n' read -d '' -r -a EUI_ARRAY <<< "$EUI_ARRAY"

declare -A EUI_STATUS
for eui in "${EUI_ARRAY[@]}"; do
    EUI_STATUS["$eui"]=0  
    # 0 means downlink not arrived
    # 1 means downlink arrived
done

while true; do
    all_downlinks_arrived=true

    printf "Downlinks sent to the gateway: \n \n"

    for eui in "${EUI_ARRAY[@]}"; do
        if [ "${EUI_STATUS["$eui"]}" -eq 0 ]; then
            LAST_DW_OLD=$(jq -r --arg eui "$eui" '.briefs[] | select(.EUI == $eui).lastDwTimestamp' JSON_output/verbose.json)
            LAST_DW_NEW=$(jq -r --arg eui "$eui" '.briefs[] | select(.EUI == $eui).lastDwTimestamp' JSON_output/verbose_new.json)

            if [ "$LAST_DW_NEW" -gt "$LAST_DW_OLD" ]; then
                printf "\e[1;32mV  Downlink from: $(jq -r --arg eui "$eui" '.briefs[] | select(.EUI == $eui).name' JSON_output/verbose.json) has arrived\n\e[0m"
                
                EUI_STATUS["$eui"]=1  # update status to downlink arrived

            else
                printf "\e[1;31mX  Downlink from: $(jq -r --arg eui "$eui" '.briefs[] | select(.EUI == $eui).name' JSON_output/verbose.json) has not arrived\n\e[0m"

                all_downlinks_arrived=false  # at least one downlink is pending
            fi
        fi
    done

    if $all_downlinks_arrived; then
        break
    fi

    printf "\n"

    i=1
    sp="/-\|"
    echo -n ' '

    # spinning bar to show progress is being made while
    # the program waits a minute to pass

    for ((j = 0; j < 60; j++)); do
        printf "\b${sp:i++%${#sp}:1}"
        sleep 1
    done

    clear

    truncate -s 0 JSON_output/verbose_new.json

    send_new_check

done

clear

jq '.briefs[].name' JSON_output/verbose.json

printf "\e[1;32m\041\041\041\041 All downlinks have arrived \041\041\041\041 \e[0m\n"

rm -rf JSON_output/*.json