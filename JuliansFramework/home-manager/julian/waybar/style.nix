{ config, nix-colors }:

with config.colorScheme.colors;
with nix-colors.lib.conversions;
''
* {
    border: none;
    border-radius: 4px;
    /* `otf-font-awesome` is required to be installed for icons */
    font-family: "Roboto Mono Medium", "FontAwesome 6 Free";
    font-size: 14px;
    min-height: 0;
}

window#waybar {
    background-color: rgba(${hexToRGBString "," base00}, 0.6);
    color: #${base05};
    transition-property: background-color;
    transition-duration: .5s;
    border-radius: 0;
}

window#waybar.hidden {
    opacity: 0.2;
}

/* application specific with point at end
window#waybar.empty {
    background-color: transparent;
}

button {
    /* Use box-shadow instead of border so the text isn't offset */
    box-shadow: inset 0 -3px transparent;
    /* Avoid rounded borders under each button name */
    border: none;
}

/* https://github.com/Alexays/Waybar/wiki/FAQ#the-workspace-buttons-have-a-strange-hover-effect */
button:hover {
    background: inherit;
    box-shadow: inset 0 -3px #ffffff;
}

#workspaces button {
    padding: 0 0.4em;
    background-color: transparent;
    color: #${base05};
}

#workspaces button:hover {
    background: rgba(${hexToRGBString "," base02}, 0.2);
}

#workspaces button.focused {
    background-color: #${base0D};
    box-shadow: inset 0 -3px #ffffff;
}

#workspaces button.active { /* for hyprland workspaces */
    background-color: #${base0D};
    box-shadow: inset 0 -3px #ffffff;
}

#workspaces button.urgent {
    background-color: #${base08};
}

#submap {
    padding: 0 0.4em;
    background-color: #${base0D};
    box-shadow: inset 0 -3px #ffffff;
}

#clock,
#battery,
#custom-mako,
#cpu,
#memory,
#disk,
#temperature,
#backlight,
#network,
#bluetooth,
#pulseaudio,
#wireplumber,
#custom-media,
#tray,
#scratchpad,
#mode,
#idle_inhibitor,

#window,
#workspaces {
    margin: 0 4px;
}

/* If workspaces is the leftmost module, omit left margin */
.modules-left > widget:first-child > #workspaces {
    margin-left: 0;
}

/* If workspaces is the rightmost module, omit right margin */
.modules-right > widget:last-child > #workspaces {
    margin-right: 0;
}

#clock {
    background-color: #${base0D};
}

#battery,
#custom-mako {
    background-color: #${base};
}

#battery.charging, #battery.plugged {
    background-color: #26A65B;
}

@keyframes blink {
    to {
        background-color: #ffffff;
        color: #000000;
    }
}

#battery.critical:not(.charging) {
    background-color: #f53c3c;
    color: #ffffff;
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: linear;
    animation-iteration-count: infinite;
    animation-direction: alternate;
}

label:focus {
    background-color: #000000;
}

#cpu {
    background-color: #2ecc71;
}

#memory {
    background-color: #9b59b6;
}

#disk {
    background-color: #964B00;
}

#backlight {
    background-color: #90b1b1;
}

#network {
    background-color: #2980b9;
}

#network.disconnected {
    background-color: #f53c3c;
}

#bluetooth {
    background-color: #7cafe2;
}

#pulseaudio {
    background-color: #f1c40f;
}

#pulseaudio.muted {
    background-color: #90b1b1;
    color: #2a5c45;
}

#wireplumber {
    background-color: #fff0f5;
}

#wireplumber.muted {
    background-color: #f53c3c;
}

#temperature {
    background-color: #f0932b;
}

#temperature.critical {
    background-color: #eb4d4b;
}

#tray {
    background-color: transparent;
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
    background-color: #eb4d4b;
}

#idle_inhibitor {
    background-color: #2d3436;
}

#idle_inhibitor.activated {
    background-color: #ecf0f1;
}

#language {
    background: #00b093;
    padding: 0 5px;
    margin: 0 5px;
    min-width: 16px;
}

#keyboard-state {
    background: #97e1ad;
    padding: 0 0px;
    margin: 0 5px;
    min-width: 16px;
}

#keyboard-state > label {
    padding: 0 5px;
}

#keyboard-state > label.locked {
    background: rgba(0, 0, 0, 0.2);
}

#scratchpad {
    background: rgba(0, 0, 0, 0.2);
    color: #ffffff;
}

#scratchpad.empty {
	background-color: transparent;
}
''
