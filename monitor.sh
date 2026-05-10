#!/bin/bash

echo "=============================="
echo "      SYSTEM MONITOR"
echo "=============================="

hostname=$(hostname)
echo "Hostname      : $hostname"

os=$(uname)
echo "OS            : $os"

uptime_info=$(uptime)
echo "Uptime        : $uptime_info"

ram_used=$(top -l 1 | grep PhysMem | awk '{print $2}')
echo "RAM Used      : $ram_used"

disk_usage=$(df -h / | awk 'NR==2 {print $5}')
echo "Disk Usage    : $disk_usage"

battery=$(pmset -g batt | grep -Eo "\d+%" | head -1)
echo "Battery       : $battery"

if ping -c 1 google.com > /dev/null
then
    echo "Internet      : Connected"
else
    echo "Internet      : Disconnected"
fi

echo "=============================="