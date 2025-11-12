#!/usr/bin/env python

import json
import os
import socket
import sys


usedMonitorDescriptions = [
    "Samsung Electric Company C27HG7x HTHK300334",
]

options = {
    "Reset to Hyprland config": "reload",
    "Inhibit suspend": "dispatch submap inhibitSuspend",
    "Enable blue light filter": "hyprsunset temperature 3500",
    "Disable blue light filter": "hyprsunset identity",
}


def send(msg: str) -> str:
    runtimeDir = os.environ["XDG_RUNTIME_DIR"]
    his = os.environ["HYPRLAND_INSTANCE_SIGNATURE"]

    # hyprsunset and hyprpaper are using their own sockets
    if msg.startswith("hyprsunset "):
        socket_name = ".hyprsunset.sock"
        msg = msg.removeprefix("hyprsunset ")
    elif msg.startswith("hyprpaper "):
        socket_name = ".hyprpaper.sock"
        msg = msg.removeprefix("hyprpaper ")
    else:
        socket_name = ".socket.sock"

    client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    client.connect(f"{runtimeDir}/hypr/{his}/{socket_name}")
    client.send(msg.encode())
    returnVal = client.recv(32768)
    client.close()

    return returnVal.decode()


# get list of connected monitors
monitors = json.loads(send("-j/monitors"))

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
    command = options[option]
    send(command)
else:
    print("\0no-custom\x1ftrue")  # set no-custom option of rofi
    print("\n".join(options.keys()))
