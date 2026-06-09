#!/usr/bin/env python

import json
import os
import socket
import sys


usedMonitorDescriptions = [
    "Samsung Electric Company C27HG7x HTHK300334",
    "Samsung Electric Company LS32A70 HNMR400480",
    "Samsung Electric Company Odyssey G70B H1AK500000",
]

options = {
    "Reset to Hyprland config": "reload",
    "Inhibit suspend": 'dispatch hl.dsp.submap("inhibitSuspend")',
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
    options[f"Scale {name} to {scale}"] = (
        f'eval hl.monitor({{output="{name}",mode="{size}",position="{pos}",scale={scale}}})'
    )

    if monitor["name"] != "eDP-1":
        # add mirror options
        if internalExists:
            options[f"Mirror eDP-1 to {name}"] = (
                f'eval hl.monitor({{output="eDP-1",mode="2256x1504",position="-1440x0",scale=1,mirror="{name}"}})'
            )

        # add tablet binding options
        options[f"Bind tablets to {name}"] = (
            f'eval hl.config({{input={{tablet={{output="{name}"}}}}}})'
        )

if len(sys.argv) > 1:
    option = sys.argv[1]
    command = options[option]
    response = send(command)
    if response != "ok":
        print(response, file=sys.stderr)
else:
    print("\0no-custom\x1ftrue")  # set no-custom option of rofi
    print("\n".join(options.keys()))
