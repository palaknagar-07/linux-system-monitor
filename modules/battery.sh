#!/bin/bash
# Battery monitoring module

get_battery() {
    pmset -g batt | grep -Eo "\d+%" | head -1
}