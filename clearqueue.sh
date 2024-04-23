#!/bin/bash

source tokenservice.sh

rm -rf JSON_output/*.json

curl \
   -H "Authorization: Bearer $(token)" \
   -H "Accept: application/json" \
   -s --show-error --fail \
   "https://community.thingpark.io/thingpark/wireless/rest/subscriptions/mine/devices?name=PED&healthState=ACTIVE&connectivity=LORAWAN&sort=lastUpTimestamp%2Cdesc" | jq \
   >> JSON_output/clearqueue.json

eui=$(jq '.briefs[0].EUI' JSON_output/clearqueue.json)

curl -X 'POST' \
        "https://community.thingpark.io/thingpark/wireless/rest/subscriptions/mine/devices/e$eui/admins/downlink?payload=ff030300&fPort=1&confirmed=true&flushDownlinkQueue=false" \
        -H "Authorization: Bearer $(token)" \
        -H "Accept: application/json" \
        -d ''

printf "Queue cleared. \n"