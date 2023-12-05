#!/usr/bin/env bash 

ENABLED=
DISABLED=

# only enable the following if you run this script in a regular interval
#COUNT=$(makoctl list | grep -o app-name | wc -l)
#if [ $COUNT != 0 ]; then DISABLED=" $COUNT"; fi 

sleep 0.1 #required because else makoctl won't have updated yet after changing mode
if [ $(makoctl mode | grep -c "doNotDisturb") -eq 0 ] ; then echo $ENABLED; else echo $DISABLED; fi
