#!/bin/bash
# Network monitoring module

check_internet() {
    if ping -c 1 google.com > /dev/null
    then
        echo "Connected"
    else
        echo "Disconnected"
    fi
}