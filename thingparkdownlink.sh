#!/bin/bash

CLIENT_ID=$(cat keys/CLIENT_ID)
CLIENT_SECRET=$(cat keys/CLIENT_SECRET)

echo "Payload a ser enviado:"

read -r PAYLOAD

token() {
  : "${_expires_at:=0}"
  local current_time
  current_time=$(date '+%s')
  local time_difference
  time_difference=$(( _expires_at - current_time ))
  if (( time_difference < 30 )); then
    local json_response
    json_response=$(curl \
      -s --show-error --fail \
      -d "client_id=$CLIENT_ID" \
      -d "client_secret=$CLIENT_SECRET" \
      -d "grant_type=client_credentials" \
      https://community.thingpark.io/users-auth/protocol/openid-connect/token)
    local expires_in
    expires_in=$(echo "$json_response" | jq -r '.expires_in')
    _expires_at=$((current_time + expires_in))
    ACCESS_TOKEN=$(echo "$json_response" | jq -r '.access_token')
  fi
  echo "$ACCESS_TOKEN"
}

send_request() {
    eui="$1"
    name="$2"
    local access_token
    access_token=$(token)

    curl -X 'POST' \
    "https://community.thingpark.io/thingpark/wireless/rest/subscriptions/mine/devices/e$eui/admins/downlink?payload=$PAYLOAD&fPort=1&confirmed=true&flushDownlinkQueue=true" \
    -H "Authorization: Bearer $access_token" \
    -H "Accept: application/json" \
    -d ''

    echo "Downlink sent to gateway at $(date '+%T.%3N') on badge: $name"
}
export -f token
export -f send_request

truncate -s 0 JSON_output/verbose.json

echo "Nome dentro da Actility para filtrar:"

read -r NAME_FILTER

curl \
   -H "Authorization: Bearer $(token)" \
   -H "Accept: application/json" \
   -s --show-error --fail \
   "https://community.thingpark.io/thingpark/wireless/rest/subscriptions/mine/devices?name=$NAME_FILTER&healthState=ACTIVE" | jq \
   >> JSON_output/verbose.json

truncate -s 0 JSON_output/final.json

jq '[.briefs[] | {Name: .name, EUI: .EUI}]' JSON_output/verbose.json >> JSON_output/final.json

rm -rf JSON_output/verbose.json

EUI_ARRAY=$(jq -r '.[].EUI' JSON_output/final.json)
NAME_ARRAY=$(jq -r '.[].Name' JSON_output/final.json)

IFS=$'\n' read -d '' -r -a EUI_ARRAY <<< "$EUI_ARRAY"
IFS=$'\n' read -d '' -r -a NAME_ARRAY <<< "$NAME_ARRAY"

for ((i = 0; i < ${#EUI_ARRAY[@]}; i++)); do
    eui=${EUI_ARRAY[i]}
    name=${NAME_ARRAY[i]}
    send_request "$eui" "$name" &
done
wait