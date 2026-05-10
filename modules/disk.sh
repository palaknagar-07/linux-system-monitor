#!/bin/bash
# Disk monitoring module

get_disk_usage() {
    usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

    if [ "$usage" -gt 80 ]
    then
        echo "WARNING: ${usage}%"
    else
        echo "${usage}%"
    fi
}