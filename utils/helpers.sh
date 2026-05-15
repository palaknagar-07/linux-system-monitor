#!/bin/bash
# Helper functions

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

get_platform() {
    uname -s
}

is_macos() {
    [ "$(get_platform)" = "Darwin" ]
}

is_linux() {
    [ "$(get_platform)" = "Linux" ]
}

format_percent_status() {
    local value="$1"
    local warning="${2:-80}"
    local critical="${3:-90}"

    if [ -z "$value" ]; then
        echo "Unavailable"
    elif [ "$value" -ge "$critical" ]; then
        echo "CRITICAL: ${value}%"
    elif [ "$value" -ge "$warning" ]; then
        echo "WARNING: ${value}%"
    else
        echo "${value}%"
    fi
}

json_escape() {
    local value="$1"
    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    value=${value//$'\n'/\\n}
    printf '%s' "$value"
}
