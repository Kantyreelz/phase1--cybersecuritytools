#!/bin/bash
# Show help or report an unknown option
if [ "$1" = "--help" ]; then
    echo "Linux Security Checker"
    echo "Usage: bash linuxsecuritychecker.sh [--help]"
    echo "Checks the firewall, SSH service, and password-file permissions."
    exit 0
elif [ "$1" != "" ]; then
    echo "Error: unknown option: $1"
    echo "Use --help for instructions."
    exit 1
else
    echo "Starting security checks..."
fi

# Linux Security Checker
# Checks a few basic security settings on this Linux computer.

echo "================================"
echo "       LINUX SECURITY CHECKER"
echo "================================"

# Check whether the UFW firewall tool is available
# Check whether the ufw command is installed.
# > /dev/null hides normal output; 2>&1 hides error messages.
# The if statement still sees whether the command was found.

echo "Firewall check:"

if command -v ufw > /dev/null 2>&1; then
    sudo ufw status
else
    echo "UFW is not installed."
fi

echo ""

# Check whether the SSH service is running
echo "SSH service check:"

if systemctl is-active --quiet ssh; then
    echo "SSH service is running."
else
    echo "SSH service is not running."
fi

echo ""

# Check whether the current user can read the password-hash file
echo "Password-file permission check:"

if [ -r /etc/shadow ]; then
    echo "WARNING: the current user can read /etc/shadow."
else
    echo "OK: the current user cannot read /etc/shadow."
fi

