{ config, pkgs, ... }:

{
  # set scripts for extended Hyprland behavior (suspend, lock, etc.)
  home.file = {
    "clamshell_mode_hypr.sh" = {
      target = ".systemScripts/clamshell_mode_hypr.sh";
      source = ./systemScripts/clamshell_mode_hypr.sh;
      executable = true;
    };
    "lockAndSuspend.sh" = {
      target = ".systemScripts/lockAndSuspend.sh";
      source = ./systemScripts/lockAndSuspend.sh;
      executable = true;
    };
    "hyprland_output_options.py" = {
      target = ".systemScripts/hyprland_output_options.py";
      source = ./systemScripts/hyprland_output_options.py;
      executable = true;
    };
  };

  # Hyprland config
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    extraConfig = with config.colorScheme.palette; ''
# ----- Monitor config ---------------------------------------------------------
# internal monitor (fractional scaling)
monitor=eDP-1, 2256x1504, -1440x0, 1.566667
# Samsung C27HG7x
monitor=desc:Samsung Electric Company C27HG7x HTHK300334, 2560x1440@144, 0x0, 1
# Iiyama PL2280H
monitor=HDMI-A-1, 1920x1080@60, 2560x0, 1
# fallback rule for random monitors
monitor=,preferred,auto,auto

# Set lockscreen background
$lock_bg = /home/julian/Pictures/ufp_ac.jpg


# ----- Initialisation ---------------------------------------------------------
# Execute your favorite apps at launch (waybar gets started automatically through systemd)
exec-once = wl-paste --type text --watch cliphist store #clipboard manager: Stores only text data
exec-once = wl-paste --type image --watch cliphist store #clipboard manager: Stores only image data
exec-once = wl-paste -t text -w xclip -selection clipboard
exec-once=dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = ${pkgs.libsForQt5.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1
exec-once=[workspace 1 silent] kwalletd6
exec-once=[workspace 10 silent] thunderbird
exec-once=[workspace 1 silent] sleep 1 && keepassxc
exec-once=[silent] sleep 2 && element-desktop --hidden
exec-once=[silent] sleep 2 && slack -s -u
exec-once=[silent] sleep 2 && signal-desktop --no-sandbox --start-in-tray
exec-once=[silent] sleep 2 && nextcloud
exec-once=[silent] sleep 2 && webcord -m
exec-once=[silent] xwaylandvideobridge

# Env vars that get set at startup
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
env = QT_QPA_PLATFORM,wayland;xcb
env = QT_AUTO_SCREEN_SCALE_FACTOR,1
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
env = GDK_BACKEND,wayland,x11
env = CLUTTER_BACKEND,wayland
env = NIXOS_OZONE_WL,1
#tearing
#env = WLR_DRM_NO_ATOMIC,1
#windowrulev2 = immediate, class:^(cs2)$


# ----- Window Rules -----------------------------------------------------------
# xwayland screen sharing
windowrulev2 = opacity 0.0 override 0.0 override,class:^(xwaylandvideobridge)$
windowrulev2 = noanim,class:^(xwaylandvideobridge)$
windowrulev2 = nofocus,class:^(xwaylandvideobridge)$
windowrulev2 = noinitialfocus,class:^(xwaylandvideobridge)$


# ----- Look & Feel ------------------------------------------------------------
general {
    gaps_in = 3
    gaps_out = 0
    border_size = 2
    col.active_border = rgb(${base0B}) rgb(${base0D}) 45deg
    col.inactive_border = rgb(${base02})
    col.nogroup_border = rgb(${base02})
    col.nogroup_border_active = rgb(${base08}) rgb(${base0E}) 45deg

    layout = dwindle
    #allow_tearing = true
}

dwindle {
    pseudotile = true # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
    preserve_split = true #without this the wm will rearrange windows when resizing a window
    force_split = 2 # always split to right/bottom
}

group {
    col.border_active = rgb(${base0B}) rgb(${base0D}) 45deg
    col.border_inactive = rgb(${base02})
    col.border_locked_active = rgb(${base0C}) rgb(${base0E}) 45deg
    col.border_locked_inactive = rgb(${base02})
    groupbar {
        text_color = rgb(${base05})
        col.active = rgb(${base0B}) rgb(${base0D}) 45deg
        col.inactive = rgb(${base02})
        col.locked_active = rgb(${base0C}) rgb(${base0E}) 45deg
        col.locked_inactive = rgb(${base02})
    }
}

decoration {
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
    col.shadow = rgb(${base00})
}

animations {
    enabled = true

    #default animations
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 5, myBezier
    animation = windowsOut, 1, 5, default, popin 80%
    animation = border, 1, 7, default
    animation = borderangle, 1, 5, default
    animation = fade, 1, 5, default
    animation = workspaces, 1, 5, default
}

xwayland {
    force_zero_scaling = true
}

misc {
    col.splash = rgb(${base05})
    background_color = rgb(${base00})
    # vrr = 2
}


# ----- Input & Bindings -------------------------------------------------------
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

gestures {
    workspace_swipe = true
}

binds {
    allow_workspace_cycles = true #previous now cycles between last two used workspaces (alt+tab behaviour)
}

$mainMod = SUPER

#essential application shortcuts
bind = $mainMod, RETURN, exec, alacritty
bind = $mainMod, A, exec, dolphin
bind = $mainMod, D, exec, rofi -show drun
bind = $mainMod, C, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy
bind = $mainMod SHIFT, C, exec, cliphist wipe

#basic stuff
bind = $mainMod SHIFT, Q, killactive,
bind = $mainMod SHIFT, E, exit,
bind = $mainMod SHIFT, SPACE, togglefloating,
bind = $mainMod, T, pseudo, # dwindle
bind = $mainMod, V, togglesplit, # dwindle
bind = $mainMod, F, fullscreen 

# Move focus (with mainMod + arrow keys + vim keys)
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d
bind = $mainMod, H, movefocus, l
bind = $mainMod, L, movefocus, r
bind = $mainMod, K, movefocus, u
bind = $mainMod, J, movefocus, d

# Switch workspaces (with mainMod + [0-9])
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

# Switch workspaces (with TAB)
bind = ALT, TAB, workspace, previous
bind = $mainMod, TAB, workspace, e+1
bind = $mainMod SHIFT, TAB, workspace, e-1

# Switch workspaces (with mainMod + Scroll (mouse))
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Move active window (with mainMod + SHIFT + vim keys)
bind = $mainMod SHIFT, left, movewindow, l
bind = $mainMod SHIFT, right, movewindow, r
bind = $mainMod SHIFT, up, movewindow, u
bind = $mainMod SHIFT, down, movewindow, d
bind = $mainMod SHIFT, H, movewindow, l
bind = $mainMod SHIFT, L, movewindow, r
bind = $mainMod SHIFT, K, movewindow, u
bind = $mainMod SHIFT, J, movewindow, d

# Move/resize active window (with mainMod + LMB/RMB and dragging)
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Move workspace (multi monitor)
bind = $mainMod ALT, left, movecurrentworkspacetomonitor, -1
bind = $mainMod ALT, right, movecurrentworkspacetomonitor, +1
bind = $mainMod ALT, H, movecurrentworkspacetomonitor, -1
bind = $mainMod ALT, L, movecurrentworkspacetomonitor, +1

# Move active window to a workspace (with mainMod + SHIFT + [0-9])
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

# screenshot (print: active window, framework key/scroll lock (laptop/docked): area. With mainmod: copysave, Without: copy)
$screenshotDir = /home/julian/Pictures/Screenshots
bind = , Print, exec, grimblast --notify copy active 
bind = $mainMod, Print, exec, grimblast --notify copysave active "$screenshotDir/$(date +"%Y%m%d_%T")-Screenshot-active.png"
bind = , Scroll_Lock, exec, grimblast --notify --freeze copy area
bind = , XF86AudioMedia, exec, grimblast --notify --freeze copy area
bind = $mainMod, Scroll_Lock, exec, grimblast --notify --freeze copysave area "$screenshotDir/$(date +"%Y%m%d_%T")-Screenshot-area.png"
bind = $mainMod, XF86AudioMedia, exec, grimblast --notify --freeze copysave area "$screenshotDir/$(date +"%Y%m%d_%T")-Screenshot-area.png"

#hyprpicker 
bind = ALT, Print, exec, hyprpicker -a -r

# hyprctl kill 
bind = $mainMod, X, exec, hyprctl kill

# shortcut to mute mic (only used when docked since laptop doesn't have pause button)
bindl = , Pause, exec, pactl set-source-mute @DEFAULT_SOURCE@ toggle

#lid uspend & lock screen & dpms (Lid Switch)
bindl = , switch:Lid Switch, exec, /home/julian/.systemScripts/clamshell_mode_hypr.sh $lock_bg
bind = $mainMod, Y, exec, swaylock -f -c 000000 -i $lock_bg

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
#has to be SUPER + P since the multi-monitor key on the framework laptop triggers exactly that combination
bind = SUPER, P, exec, rofi -show output -modes "output:~/.systemScripts/hyprland_output_options.py"

# inhibitSuspend submap
submap = inhibitSuspend
bindl = , switch:Lid Switch, exec, /home/julian/.systemScripts/clamshell_mode_hypr.sh $lock_bg inhibitSuspend

bindle = , XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%
bindle = , XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%
bindl = , XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle
bindl = , XF86AudioMicMute, exec, pactl set-source-mute @DEFAULT_SOURCE@ toggle
bindle = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
bindle = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
bindl = , XF86AudioPlay, exec, playerctl play-pause
bindl = , XF86AudioNext, exec, playerctl next
bindl = , XF86AudioPrev, exec, playerctl previous
bindl = , XF86PowerOff, exec, /home/julian/.systemScripts/lockAndSuspend.sh $lock_bg 1 inhibitSuspend

bind = ,escape,submap,reset

submap = reset
    '';
  };
}
