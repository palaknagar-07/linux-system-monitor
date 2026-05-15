#!/bin/bash
# System monitoring module

get_hostname() {
    hostname
}

get_os() {
    uname -s
}

get_uptime() {
    uptime | sed 's/^[[:space:]]*//'
}
