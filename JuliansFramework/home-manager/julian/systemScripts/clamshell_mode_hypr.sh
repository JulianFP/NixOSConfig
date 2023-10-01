#!/usr/bin/env bash
if grep -q open /proc/acpi/button/lid/LID0/state; then
    hyprctl reload
else
    monitorCount=$(hyprctl monitors | grep -c Monitor)
    if [ $monitorCount -eq 1 ]; then
        /home/julian/.systemScripts/lockAndSuspend.sh $1 0
    else
        hyprctl keyword monitor eDP-1,disable
    fi
fi
