#!/usr/bin/env bash
swaylockProcesses=$(ps aux | grep -c swaylock)
if [ $swaylockProcesses -le 1 ]; then
    swaylock -f -c 000000 -i $1
fi
systemctl suspend
