#!/bin/bash

configure_device() {
    echo "$(<config.cfg)" > "$1"
}

badge_ports=()

while IFS= read -r -d '' port; do
    badge_ports+=("$port")
done < <(find /dev -name 'ttyACM*' -print0)

for badge in "${badge_ports[@]}"; do
    eval "$(configure_device "$badge")"
    printf '%s\n' "$badge" &
done