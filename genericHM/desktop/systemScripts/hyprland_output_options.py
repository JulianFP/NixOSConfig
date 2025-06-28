#!/usr/bin/env python

import json
import os
import socket
import sys

import dbus

session_bus = dbus.SessionBus()
systemd1 = session_bus.get_object("org.freedesktop.systemd1", "/org/freedesktop/systemd1")
manager = dbus.Interface(systemd1, "org.freedesktop.systemd1.Manager")

runtimeDir = os.environ["XDG_RUNTIME_DIR"]
his = os.environ["HYPRLAND_INSTANCE_SIGNATURE"]


def send(msg: str) -> str:
    client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    client.connect(runtimeDir + "/hypr/" + his + "/.socket.sock")
    client.send(msg.encode())
    returnVal = client.recv(4096)
    client.close()
    return returnVal.decode()


monitors = json.loads(send("-j/monitors"))

usedMonitorDescriptions = [
    "Samsung Electric Company C27HG7x HTHK300334",
]

options = {
    "Reset to Hyprland config": "reload",
    "Inhibit suspend": "dispatch submap inhibitSuspend",
}

systemdUnits = {
    "blue light filter": "hyprsunset.service",
}
systemdUnitsStart = {}


# add systemd units depending on current state
for unitDesc, unitName in systemdUnits.items():
    unit = session_bus.get_object("org.freedesktop.systemd1", object_path=manager.GetUnit(unitName))
    interface = dbus.Interface(unit, dbus_interface="org.freedesktop.DBus.Properties")
    if interface.Get("org.freedesktop.systemd1.Unit", "ActiveState") == "active":
        options["Disable " + unitDesc] = unitName
        systemdUnitsStart[unitName] = False
    else:
        options["Enable " + unitDesc] = unitName
        systemdUnitsStart[unitName] = True

# check if eDP-1 exists
internalExists = False
for monitor in monitors:
    if monitor["name"] == "eDP-1":
        internalExists = True
        break

for monitor in monitors:
    name = (
        monitor["name"]
        if monitor["description"] not in usedMonitorDescriptions
        else "desc:" + monitor["description"]
    )
    size = str(monitor["width"]) + "x" + str(monitor["height"])
    pos = str(monitor["x"]) + "x" + str(monitor["y"])

    # add scaling options
    scale = "2" if monitor["scale"] == 1 else "1"
    options["Scale " + name + " to " + scale] = (
        "keyword monitor " + name + "," + size + "," + pos + "," + scale
    )

    if monitor["name"] != "eDP-1":
        # add mirror options
        if internalExists:
            options["Mirror eDP-1 to " + name] = (
                "keyword monitor eDP-1,2256x1504,-1440x0,1,mirror," + name
            )

        # add tablet binding options
        options["Bind tablets to " + name] = "keyword input:tablet:output " + name

if len(sys.argv) > 1:
    option = sys.argv[1]
    if options[option] in systemdUnits.values():
        if systemdUnitsStart[options[option]]:
            manager.StartUnit("hyprsunset.service", "fail")
        else:
            manager.StopUnit("hyprsunset.service", "fail")
    else:
        command = options[option]
        send(command)
else:
    print("\0no-custom\x1ftrue")  # set no-custom option of rofi
    print("\n".join(options.keys()))
