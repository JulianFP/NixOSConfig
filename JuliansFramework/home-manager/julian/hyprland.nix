{ config, pkgs, ... }:

{
  # set scripts for extended Hyprland behavior (suspend, lock, etc.)
  home.file = {
    "clamshell_mode_hypr.sh" = {
      target = ".systemScripts/clamshell_mode_hypr.sh";
      source = ./systemScripts/clamshell_mode_hypr.sh;
      executable = true;
    };
    "gamingMode_hypr.sh" = {
      target = ".systemScripts/gamingMode_hypr.sh";
      source = ./systemScripts/gamingMode_hypr.sh;
      executable = true;
    };
    "lockAndSuspend.sh" = {
      target = ".systemScripts/lockAndSuspend.sh";
      source = ./systemScripts/lockAndSuspend.sh;
      executable = true;
    };
  };

  # Hyprland config
  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = ''
# This is an example Hyprland config file.
#
# Refer to the wiki for more information.

#
# Please note not all available settings / options are set here.
# For a full list, see the wiki
#

# See https://wiki.hyprland.org/Configuring/Monitors/
# internal monitor (fractional scaling)
monitor=eDP-1, 2256x1504, 0x0, 1.5
# Samsung C27HG7x (ports on right and left downside)
monitor=DP-2, 2560x1440@144, 1504x0, 1
monitor=DP-3, 2560x1440@144, 0x0, 1
# Iiyama PL2280H (ports over DS at right and left upside)
monitor=DP-5, 1920x1080, 0x0, 1
monitor=DP-6, 1920x1080, 1920x0, 1

# See https://wiki.hyprland.org/Configuring/Keywords/ for more
# Set lockscreen background
$lock_bg = /home/julian/Pictures/ufp_ac.jpg

# Execute your favorite apps at launch
exec-once = waybar #status bar
exec-once = wl-paste --type text --watch cliphist store #clipboard manager: Stores only text data
exec-once = wl-paste --type image --watch cliphist store #clipboard manager: Stores only image data
exec-once = wl-paste -t text -w xclip -selection clipboard
exec-once=dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = ${pkgs.libsForQt5.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1
exec-once=[workspace 1 silent] kwalletd5
exec-once=[workspace 1 silent] thunderbird
exec-once=[workspace 1 silent] sleep 1 && keepassxc
exec-once=[workspace 1 silent] sleep 1 && signal-desktop --no-sandbox --start-in-tray
exec-once=[workspace 1 silent] sleep 1 && nextcloud
exec-once=[silent] sleep 1 && webcord -m --safe-mode
exec-once=[silent] xwaylandvideobridge

# xwayland screen sharing
windowrulev2 = opacity 0.0 override 0.0 override,class:^(xwaylandvideobridge)$
windowrulev2 = noanim,class:^(xwaylandvideobridge)$
windowrulev2 = nofocus,class:^(xwaylandvideobridge)$
windowrulev2 = noinitialfocus,class:^(xwaylandvideobridge)$

# Source a file (multi-file configs)
# source = ~/.config/hypr/myColors.conf

# Some default env vars.
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
env = QT_QPA_PLATFORM,wayland;xcb
env = QT_AUTO_SCREEN_SCALE_FACTOR,1
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
env = GDK_BACKEND,wayland,x11
env = CLUTTER_BACKEND,wayland
env = NIXOS_OZONE_WL,1

# For all categories, see https://wiki.hyprland.org/Configuring/Variables/
input {
    kb_layout = de
    kb_variant =
    kb_model =
    kb_options =
    kb_rules =

    follow_mouse = 1

    touchpad {
        natural_scroll = true
    }
    sensitivity = 0 # -1.0 - 1.0, 0 means no modification.
}

general {
    # See https://wiki.hyprland.org/Configuring/Variables/ for more

    gaps_in = 3
    gaps_out = 0
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)

    layout = dwindle
}

xwayland {
    force_zero_scaling = true
}

decoration {
    # See https://wiki.hyprland.org/Configuring/Variables/ for more
    blur {
        enabled = true
        size = 3
        passes = 1
        new_optimizations = true
    }

    rounding = 5

    drop_shadow = true
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

animations {
    enabled = true

    # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

    bezier = myBezier, 0.05, 0.9, 0.1, 1.05

    animation = windows, 1, 5, myBezier
    animation = windowsOut, 1, 5, default, popin 80%
    animation = border, 1, 7, default
    animation = borderangle, 1, 5, default
    animation = fade, 1, 5, default
    animation = workspaces, 1, 5, default
}

dwindle {
    # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
    pseudotile = true # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
    preserve_split = true # you probably want this
    force_split = 2 # always split to right/bottom
}

master {
    # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
    new_is_master = true
}

gestures {
    # See https://wiki.hyprland.org/Configuring/Variables/ for more
    workspace_swipe = true
}

Misc {
    key_press_enables_dpms = true
}

# Example per-device config
# See https://wiki.hyprland.org/Configuring/Keywords/#per-device-input-configs for more
# device:epic-mouse-v1 {
#     sensitivity = -0.5
# }

# Example windowrule v1
# windowrule = float, ^(kitty)$
# Example windowrule v2
# windowrulev2 = float,class:^(kitty)$,title:^(kitty)$
# See https://wiki.hyprland.org/Configuring/Window-Rules/ for more


# See https://wiki.hyprland.org/Configuring/Keywords/ for more
$mainMod = SUPER

binds {
    allow_workspace_cycles = true #previous now cycles between last two used workspaces (alt+tab behaviour)
}

# Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
bind = $mainMod, RETURN, exec, alacritty
bind = $mainMod SHIFT, Q, killactive,
bind = $mainMod SHIFT, E, exit,
bind = $mainMod, Q, exec, dolphin
bind = $mainMod SHIFT, SPACE, togglefloating,
bind = $mainMod, D, exec, rofi -show drun
bind = $mainMod, C, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy
bind = $mainMod SHIFT, C, exec, cliphist wipe
bind = $mainMod, P, pseudo, # dwindle
bind = $mainMod, V, togglesplit, # dwindle
bind = $mainMod, F, fullscreen 

# Move focus with mainMod + arrow keys + vim keys
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d
bind = $mainMod, H, movefocus, l
bind = $mainMod, L, movefocus, r
bind = $mainMod, K, movefocus, u
bind = $mainMod, J, movefocus, d

# Switch workspaces with mainMod + [0-9]
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

# Switch workspaces with ALT
bind = ALT, TAB, workspace, previous
bind = $mainMod, TAB, workspace, e+1
bind = $mainMod SHIFT, TAB, workspace, e-1

# Move active window in give direction
bind = $mainMod SHIFT, left, movewindow, l
bind = $mainMod SHIFT, right, movewindow, r
bind = $mainMod SHIFT, up, movewindow, u
bind = $mainMod SHIFT, down, movewindow, d
bind = $mainMod SHIFT, H, movewindow, l
bind = $mainMod SHIFT, L, movewindow, r
bind = $mainMod SHIFT, K, movewindow, u
bind = $mainMod SHIFT, J, movewindow, d

# Move workspace in given direction (multi monitor)
bind = $mainMod ALT, left, movecurrentworkspacetomonitor, -1
bind = $mainMod ALT, right, movecurrentworkspacetomonitor, +1
bind = $mainMod ALT, H, movecurrentworkspacetomonitor, -1
bind = $mainMod ALT, L, movecurrentworkspacetomonitor, +1

# Move active window to a workspace with mainMod + SHIFT + [0-9]
bind = $mainMod SHIFT, 1, movetoworkspacesilent, 1
bind = $mainMod SHIFT, 2, movetoworkspacesilent, 2
bind = $mainMod SHIFT, 3, movetoworkspacesilent, 3
bind = $mainMod SHIFT, 4, movetoworkspacesilent, 4
bind = $mainMod SHIFT, 5, movetoworkspacesilent, 5
bind = $mainMod SHIFT, 6, movetoworkspacesilent, 6
bind = $mainMod SHIFT, 7, movetoworkspacesilent, 7
bind = $mainMod SHIFT, 8, movetoworkspacesilent, 8
bind = $mainMod SHIFT, 9, movetoworkspacesilent, 9
bind = $mainMod SHIFT, 0, movetoworkspacesilent, 10

# Scroll through existing workspaces with mainMod + scroll
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Move/resize windows with mainMod + LMB/RMB and dragging
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# screenshot
bind = , Print, exec, grimshot copy area
bind = $mainMod, Print, exec, grimshot save area

#lid suspend & lock screen & dpms
bindl = , switch:Lid Switch, exec, /home/julian/.systemScripts/clamshell_mode_hypr.sh $lock_bg
bind = $mainMod, Y, exec, swaylock -f -c 000000 -i $lock_bg
bindl = $mainMod SHIFT, Y, exec, sleep 1 && hyprctl dispatch dpms off

# hyprctl kill 
bind = $mainMod, X, exec, hyprctl kill

# special keys
bindle = , XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%
bindle = , XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%
bindl = , XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle
bindl = , XF86AudioMicMute, exec, pactl set-source-mute @DEFAULT_SOURCE@ toggle
bindle = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
bindle = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
bindl = , XF86AudioPlay, exec, playerctl play-pause
bindl = , XF86AudioNext, exec, playerctl next
bindl = , XF86AudioPrev, exec, playerctl previous
bindl = , XF86PowerOff, exec, /home/julian/.systemScripts/lockAndSuspend.sh $lock_bg 1

# script execution
bind = $mainMod SHIFT, G, exec, /home/julian/.systemScripts/gamingMode_hypr.sh 

# groups
bind = $mainMod, W, togglegroup
    '';
  };
}
