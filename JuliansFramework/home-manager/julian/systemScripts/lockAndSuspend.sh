#!/usr/bin/env bash
swaylockProcesses=$(ps aux | grep -c swaylock)
if [ $swaylockProcesses -le 1 ]; then
    swaylock -f -c 000000 -i $1

 #do not suspend if power button called this and machine already woke up recently (during the current minute). Makes it possible to wake machine pressing the power button
elif [ $2 -eq 1 ] && journalctl -u sleep.target -S $(date +%H:%M) | grep -q "Stopped"; then
    exit 0
fi

if [ $3 == "inhibitSuspend" ]; then
    #toggle dpms if called from power button, set to off if not
    if [ $2 -eq 1 ] && hyprctl monitors | grep -q "dpmsStatus: 0"; then
        hyprctl dispatch dpms on
    else
        hyprctl dispatch dpms off
    fi
else
    systemctl suspend -i
fi
