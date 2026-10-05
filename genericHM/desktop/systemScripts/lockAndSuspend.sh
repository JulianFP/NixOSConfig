#!/usr/bin/env bash
#$1: 1 if triggered by power button, 0 if not
#$2: operation, one of "suspend", "suspend-then-hibernate", "hibernate"
hyprlockProcesses=$(pgrep -c hyprlock)
if [ "$hyprlockProcesses" -eq 0 ]; then
	#lock screen if not already locked
	hyprlock &
	sleep 1
fi

if hyprctl submap | grep -q "inhibitSuspend"; then
	#inhibitSuspend, just turn off screen instead
	if [ "$1" -eq 1 ]; then
		#if called from power button then toggle
		hyprctl dispatch 'hl.dsp.dpms({action="toggle"})'
	else
		#if called from lid close then turn off regardless of current state
		hyprctl dispatch 'hl.dsp.dpms({action="disable"})'
	fi
elif [ "$hyprlockProcesses" -gt 0 ] && [ "$1" -eq 1 ] && journalctl -u sleep.target -S "$(date +%H:%M)" | grep -q "Stopped"; then
	#do not suspend if hyprlock was already engaged, power button called this and machine already woke up recently (during the current minute). Makes it possible to wake machine pressing the power button
	exit 0
else
	#choose operation
	if [ "$2" == "hibernate" ]; then
		#whether to hibernate instead
		systemctl hibernate -i
	elif [ "$2" == "suspend-then-hibernate" ]; then
		systemctl suspend-then-hibernate -i
	else
		systemctl suspend -i
	fi
fi
