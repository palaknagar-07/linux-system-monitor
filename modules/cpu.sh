#!/bin/bash
# CPU monitoring module

get_cpu_usage() {
    cpu_idle=$(top -l 1 | grep "CPU usage" | awk '{print $7}' | sed 's/%//')

    cpu_usage=$(echo "100 - $cpu_idle" | bc)

    echo "${cpu_usage}%"
}