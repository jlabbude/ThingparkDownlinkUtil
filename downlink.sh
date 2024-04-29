#!/bin/bash

source tokenservice.sh

send_request() {
    eui="$1"
    name="$2"
    local access_token
    access_token=$(token)

    curl -X 'POST' \
        "https://community.thingpark.io/thingpark/wireless/rest/subscriptions/mine/devices/e$eui/admins/downlink?payload=$PAYLOAD&fPort=1&confirmed=true&flushDownlinkQueue=false" \
        -H "Authorization: Bearer $access_token" \
        -H "Accept: application/json" \
        -d ''

    echo "Downlink sent to gateway at $(date '+%T.%3N') on badge: $name"
}
export -f send_request

echo "Payload a ser enviado:"
read -r PAYLOAD

echo "Nome dentro da Actility para filtrar:"
read -r NAME_FILTER
export NAME_FILTER

curl \
   -H "Authorization: Bearer $(token)" \
   -H "Accept: application/json" \
   -s --show-error --fail \
   "https://community.thingpark.io/thingpark/wireless/rest/subscriptions/mine/devices?name=$NAME_FILTER&healthState=ACTIVE" | jq \
   > JSON_output/verbose.json

EUI_ARRAY=$(jq -r '.briefs[].EUI' JSON_output/verbose.json)
NAME_ARRAY=$(jq -r '.briefs[].name' JSON_output/verbose.json)

IFS=$'\n' read -d '' -r -a EUI_ARRAY <<< "$EUI_ARRAY"
IFS=$'\n' read -d '' -r -a NAME_ARRAY <<< "$NAME_ARRAY"

for ((i = 0; i < ${#EUI_ARRAY[@]}; i++)); do
    eui=${EUI_ARRAY[i]}
    name=${NAME_ARRAY[i]}
    send_request "$eui" "$name" &
done
wait

sleep 1

printf "The following devices have received the payload $PAYLOAD at $(date):\n\n" >> payloadlog.txt

source getqueue.sh
getqueue.sh