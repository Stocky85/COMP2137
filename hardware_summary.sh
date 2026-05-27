#!/bin/bash

echo ">Hardware Summary Report<"
echo

echo "Operating System:"
hostnamectl | grep  "Operating System" | cut -d':' -f2 | xargs

echo
echo "CPU:"
lscpu | grep "Model name" | cut -d':' -f2 | xargs

echo
echo "RAM:"
free -h | grep "Mem:" | awk '{print $2}'
