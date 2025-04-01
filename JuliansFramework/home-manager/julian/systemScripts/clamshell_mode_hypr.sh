#!/usr/bin/env bash
if grep -q open /proc/acpi/button/lid/LID0/state; then
    #if lid opens and eDP-1 exists then set dpms to on (in case it was off)
    if hyprctl monitors | grep -q eDP-1; then
        hyprctl dispatch dpms on
        #if eDP-1 doesn't exist, then activate it if lid opens (through a reload)
    else
        hyprctl reload
    fi
else
    monitorCount=$(hyprctl monitors | grep -c Monitor)

    #lock and suspend/dpms if there is only one monitor (probably eDP-1)
    if [ $monitorCount -eq 1 ]; then
        /home/julian/.systemScripts/lockAndSuspend.sh 0 $1
    #if there are multiple monitors, then don't lock&suspend but disable eDP-1
    else
        hyprctl keyword monitor eDP-1,disable
    fi
fi
