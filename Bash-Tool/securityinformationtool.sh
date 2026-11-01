#!/bin/bash

# Show instructions if the user asks for help
if [ "$1" = "--help" ]; then
    echo "System Information Tool"
    echo "Usage: bash securityinformationtool.sh [--help]"
    echo "Displays basic information about this Linux computer."
    exit 0
elif [ "$1" != "" ]; then
    echo "Error: unknown option: $1"
    echo "Use --help for instructions."
    exit 1
else
    echo "Collecting system information..."
fi

echo "----------------------------"
echo "   SYSTEM INFORMATION  "
echo "----------------------------"

#This should show the current user and hostname
echo "User: $USER"
echo "Hostname: $HOSTNAME"

#this should show the date and time
echo "Date: $(date +%d-%m-%Y)"
echo "Time: $(date +%H:%M:%S)"

# This should show how long the computer has been running
echo "Uptime: $(uptime -p)"

# This should show memory information
echo "Memory:"
free -h

# This should show disk space on the main drive
echo "Disk space:"
df -h /

# This should show the computer's IP addresses
echo "IP addresses:"
ip -brief address

echo "---------------------------------------"
echo "   SYSTEM INFORMATION REPORT COMPLETE  "
echo "---------------------------------------"
