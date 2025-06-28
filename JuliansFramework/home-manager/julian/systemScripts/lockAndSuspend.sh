#!/usr/bin/env bash
hyprlockProcesses=$(pgrep -c hyprlock)
if [ "$hyprlockProcesses" -eq 0 ]; then
	hyprlock &

elif [ "$1" -eq 1 ] && journalctl -u sleep.target -S "$(date +%H:%M)" | grep -q "Stopped"; then
	#do not suspend if power button called this and machine already woke up recently (during the current minute). Makes it possible to wake machine pressing the power button
	exit 0
fi

if [ "$2" == "inhibitSuspend" ]; then
	#toggle dpms if called from power button, set to off if not
	if [ "$1" -eq 1 ] && hyprctl monitors | grep -q "dpmsStatus: 0"; then
		hyprctl dispatch dpms on
	else
		hyprctl dispatch dpms off
	fi
else
	systemctl suspend-then-hibernate -i
fi
