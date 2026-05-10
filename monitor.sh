#!/bin/bash

source utils/colors.sh

source modules/system.sh
source modules/ram.sh
source modules/disk.sh
source modules/battery.sh
source modules/network.sh
source modules/cpu.sh

clear

echo -e "${CYAN}==============================${NC}"
echo -e "${GREEN}      SYSTEM MONITOR${NC}"
echo -e "${CYAN}==============================${NC}"

echo -e "${YELLOW}Hostname:${NC}      $(get_hostname)"
echo -e "${YELLOW}OS:${NC}            $(get_os)"
echo -e "${YELLOW}CPU Usage:${NC}     $(get_cpu_usage)"
echo -e "${YELLOW}RAM Usage:${NC}     $(get_ram_usage)"
echo -e "${YELLOW}Disk Usage:${NC}    $(get_disk_usage)"
echo -e "${YELLOW}Battery:${NC}       $(get_battery)"
echo -e "${YELLOW}Internet:${NC}      $(check_internet)"

echo -e "${CYAN}==============================${NC}"