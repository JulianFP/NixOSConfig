#!/usr/bin/env bash
if grep -q open /proc/acpi/button/lid/LID0/state; then
	if hyprctl monitors | grep -q eDP-1; then
		#if lid opens and eDP-1 exists then set dpms to on (in case it was off)
		hyprctl dispatch 'hl.dsp.dpms({action="enable"})'
	else
		#if lid opens and eDP-1 doesn't exist, then activate it (through a reload)
		hyprctl reload
	fi
else
	monitorCount=$(hyprctl monitors | grep -c Monitor)
	if [ "$monitorCount" -eq 1 ]; then
		#if lid closes and there is only one monitor (probably eDp-1) lock and suspend/dpms
		/home/julian/.systemScripts/lockAndSuspend.sh 0 "suspend-then-hibernate"
	else
		#if lid closes and there are multiple monitors, then don't lock&suspend but disable eDP-1
		hyprctl eval 'hl.monitor({output="eDP-1",disabled=true})'
	fi
fi
