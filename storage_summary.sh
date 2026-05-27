#!/bin/bash

echo ">Storage Summary Report<"
echo

echo "Disk Models/Sizes:"
lsblk -d -o MODEL,SIZE | grep -v "MODEL"

echo

echo "ext4 Filesystem Usage:"
df -hT | grep ext4
