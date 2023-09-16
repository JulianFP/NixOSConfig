#!/usr/bin/env bash
monitorCount=$(hyprctl monitors | grep -c Monitor)
if [ $monitorCount -eq 3 ]; then
    hyprctl keyword monitor eDP-1,disable
    hyprctl keyword monitor DP-2,1920x1080@60,0x0,1
    hyprctl keyword monitor DP-3,1920x1080@60,0x0,1
    hyprctl keyword monitor DP-5,1920x1080,1920x0,1
    hyprctl keyword monitor DP-6,1920x1080,1920x0,1
else
    hyprctl reload
    hyprctl keyword monitor DP-2,2560x1440@144,1504x0,1
    hyprctl keyword monitor DP-3,2560x1440@144,1504x0,1
    hyprctl keyword monitor DP-5,1920x1080,4064x0,1
    hyprctl keyword monitor DP-6,1920x1080,4064x0,1
fi
