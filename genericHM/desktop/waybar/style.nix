{ config }:

with config.lib.stylix.colors;
''
* {
    border: none;
    border-radius: 4px;
    font-family: "${config.stylix.fonts.serif.name}", "Symbols Nerd Font";
    font-size: ${builtins.toString config.stylix.fonts.sizes.desktop}pt;
    min-height: 0;
}

window#waybar, tooltip {
    background-color: rgba(${base00-rgb-r},${base00-rgb-g},${base00-rgb-b},${builtins.toString config.stylix.opacity.desktop});
    color: #${base05};
    transition-property: background-color;
    transition-duration: .5s;
    border-radius: 0;
}

window#waybar.hidden {
    opacity: 0.2;
}

button {
    /* Use box-shadow instead of border so the text isn't offset */
    box-shadow: inset 0 -3px transparent;
    /* Avoid rounded borders under each button name */
    border: none;
}

/* Gets applied to the following modules only: workpaces, submap, window, tray */
box.module {
    padding: 0 6px 0 6px;
}

#workspaces {
    padding: 0 0 0 0;
}

#workspaces button {
    padding: 0 0.4em;
    background-color: transparent;
    color: #${base05};
}

#workspaces button:hover {
    background: rgba(${base03-rgb-r},${base03-rgb-g},${base03-rgb-b}, 0.2);
}

#workspaces button.focused {
    background-color: #${base02};
    box-shadow: inset 0 -3px #${base05};
}

#workspaces button.active { /* for hyprland workspaces */
    background-color: #${base02};
    box-shadow: inset 0 -3px #${base05};
}

#workspaces button.urgent {
    background-color: #${base08};
}

/* Hyprland submapping  */
#submap {
    padding: 0 0.4em;
    background-color: #${base02};
    box-shadow: inset 0 -3px #${base05};
}

#clock,
#battery,
#custom-mako,
#cpu,
#memory,
#temperature,
#backlight,
#network,
#bluetooth,
#pulseaudio {
    background-color: #${base01};
    margin: 2px 0 2px 4px;
    padding: 0 6px 0 6px;
}

#clock {
    font-family: "${config.stylix.fonts.monospace.name}";
}

#network,
#bluetooth {
    color: #${base0D};
}

#cpu,
#custom-mako.notifications:not(.disabled),
#battery.charging, #battery.plugged {
    color: #${base0B};
}

#temperature.critical,
#network.disconnected,
#custom-mako.disabled {
    color: #${base08};
}

@keyframes blink {
    to {
        color: #${base05};
    }
}

#battery.critical:not(.charging) {
    color: #${base08};
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: linear;
    animation-iteration-count: infinite;
    animation-direction: alternate;
}

#memory {
    color: #${base0E};
}

#disk {
    color: #${base09};
}

#pulseaudio {
    color: #${base0A};
}

#pulseaudio.muted {
    color: #${base03};
}

#temperature {
    color: #${base09};
}

#backlight {
    color: #${base0C};
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
    background-color: #${base08};
}
''
