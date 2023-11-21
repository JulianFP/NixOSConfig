#!/usr/bin/env bash
swaylockProcesses=$(ps aux | grep -c swaylock)
if [ $swaylockProcesses -le 1 ]; then
    swaylock -f -c 000000 -i $1

 #do not suspend if machine already woke up recently (during the current minute). Makes it possible to wake machine pressing the power button
elif journalctl -u sleep.target -S $(date +%H:%M) | grep -q "Stopped"; then
    if [[ $2 = 1 ]]; then #only do this if power button called this script
        exit 0
    fi
fi
systemctl suspend -i
