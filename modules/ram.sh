#!/bin/bash
# RAM monitoring module

get_ram_usage() {
    top -l 1 | grep PhysMem | awk '{print $2}'
}