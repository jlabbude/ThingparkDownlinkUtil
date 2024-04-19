#!/bin/bash

clear

source tokenservice.sh

# sanitizes the json files before using them
truncate -s 0 JSON_output/verbose_new.json
truncate -s 0 JSON_output/final_new.json

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

    jq '[.briefs[] | {Name: .name, EUI: .EUI}]' JSON_output/verbose_new.json >> JSON_output/final_new.json

}

send_new_check

EUI_ARRAY=$(jq -r '.[].EUI' JSON_output/final_new.json)
IFS=$'\n' read -d '' -r -a EUI_ARRAY <<< "$EUI_ARRAY"

declare -A EUI_STATUS
for eui in "${EUI_ARRAY[@]}"; do
    EUI_STATUS["$eui"]=0  
    # 0 means downlink not arrived
    # 1 means downlink arrived
done

while true; do
    all_downlinks_arrived=true

    for eui in "${EUI_ARRAY[@]}"; do
        if [ "${EUI_STATUS["$eui"]}" -eq 0 ]; then
            LAST_DW_OLD=$(jq -r --arg eui "$eui" '.briefs[] | select(.EUI == $eui).lastDwTimestamp' JSON_output/verbose.json)
            LAST_DW_NEW=$(jq -r --arg eui "$eui" '.briefs[] | select(.EUI == $eui).lastDwTimestamp' JSON_output/verbose_new.json)

            if [ "$LAST_DW_NEW" -gt "$LAST_DW_OLD" ]; then
                jq -r --arg eui "$eui" 'del(.[] | select(.EUI == $eui))' JSON_output/final.json > JSON_output/tmp.json && mv JSON_output/tmp.json JSON_output/final.json
                
                echo "   Downlink from: $(jq -r --arg eui "$eui" '.[] | select(.EUI == $eui).Name' JSON_output/final_new.json) has arrived"
                
                EUI_STATUS["$eui"]=1  # update status to downlink arrived

            else
                echo "X  Downlink from: $(jq -r --arg eui "$eui" '.[] | select(.EUI == $eui).Name' JSON_output/final_new.json) has not arrived"

                all_downlinks_arrived=false  # at least one downlink is pending
            fi
        fi
    done

    sleep 5

    clear

    if $all_downlinks_arrived; then
        break
    fi

    printf "The downlinks of the following devices are still on queue: \n \n"
    
    jq '.[].Name' JSON_output/final.json

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
    truncate -s 0 JSON_output/final_new.json

    send_new_check

    EUI_ARRAY=$(jq -r '.[].EUI' JSON_output/final_new.json)
    IFS=$'\n' read -d '' -r -a EUI_ARRAY <<< "$EUI_ARRAY"

done

echo "All downlinks have arrived"

rm -rf JSON_output/*.json