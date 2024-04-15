#!/usr/bin/env bash 
#
#this script only checks the current mako mode. The setting is done in the "on-click" command of waybar
#
COUNT=$(makoctl list | grep -o app-name | wc -l)

if [ $COUNT -ne 0 ]; then 
    ENABLED="{\"text\": \" ${COUNT}\", \"tooltip\": \"Notifications enabled\", \"class\": [\"enabled\", \"notifications\"]}"
    DISABLED="{\"text\": \" ${COUNT}\", \"tooltip\": \"Notifications disabled\", \"class\": [\"disabled\", \"notifications\"]}"
else
    ENABLED="{\"text\": \"\", \"tooltip\": \"Notifications enabled\", \"class\": \"enabled\"}"
    DISABLED="{\"text\": \"\", \"tooltip\": \"Notifications disabled\", \"class\": \"disabled\"}"
fi


sleep 0.1 #required because else makoctl won't have updated yet after changing mode
if [ $(makoctl mode | grep -c "doNotDisturb") -eq 0 ] ; then echo "${ENABLED}"; else echo "${DISABLED}"; fi
