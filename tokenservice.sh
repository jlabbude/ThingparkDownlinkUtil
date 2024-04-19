#!/bin/bash

CLIENT_ID=$(cat keys/CLIENT_ID)
CLIENT_SECRET=$(cat keys/CLIENT_SECRET)

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

export -f token