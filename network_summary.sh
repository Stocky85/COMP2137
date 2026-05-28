#!/bin/bash

echo ">Network Configuration Summary Report<"
echo

echo "Interfaces/NIC Details:"
ip link show | awk -F': ' '{print $2}'

echo
echo "IP Addresses:"
ip -4 addr show | grep inet | awk '{print $2, $NF}'

echo
echo "Default Gateway:"
ip route | grep default | awk '{print $3}'
