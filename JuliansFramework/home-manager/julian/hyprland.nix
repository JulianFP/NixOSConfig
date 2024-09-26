{ pkgs, ... }:

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
    systemd = {
      enable = true;
      variables = [ "--all" ];
    };

    settings = {
      /* -- Monitor config -- */
      # Set lockscreen background
      "$lock_bg" = "/home/julian/Pictures/ufp_ac.jpg";

      monitor = [
        # internal monitor (fractional scaling)
        "eDP-1, 2256x1504, 0x0, 1.566667"
        # Samsung C27HG7x
        "desc:Samsung Electric Company C27HG7x HTHK300334, 2560x1440@144, 1440x0, 1"
        # Iiyama PL2280H
        "HDMI-A-1, 1920x1080@60, 4000x0, 1"
        # fallback rule for random monitors
        ",preferred,auto,auto"
      ];


      /* -- Initialisation -- */
      exec-once = [
        # Execute your favorite apps at launch (waybar gets started automatically through systemd)
        "wl-paste --type text --watch cliphist store #clipboard manager: Stores only text data"
        "wl-paste --type image --watch cliphist store #clipboard manager: Stores only image data"
        "wl-paste -t text -w xclip -selection clipboard"
        "${pkgs.libsForQt5.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1"
        "[workspace 1 silent] kwalletd6"
        "[workspace 10 silent] thunderbird"
        "[workspace 1 silent] sleep 1 && keepassxc"
        "[silent] sleep 2 && element-desktop --hidden"
        "[silent] sleep 2 && slack -s -u"
        "[silent] sleep 2 && env LANGUAGE='en-US:de-DE' signal-desktop --no-sandbox --start-in-tray"
        "[silent] sleep 2 && nextcloud"
        "[silent] sleep 2 && webcord -m"
        "[silent] sleep 2 && guilded"
        "[silent] xwaylandvideobridge"
      ];

      env = [
        # Env vars that get set at startup
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "GDK_BACKEND,wayland,x11"
        "CLUTTER_BACKEND,wayland"
        "_JAVA_AWT_WM_NONREPARENTING,1" #tiling wm fix for Java applications
        "NIXOS_OZONE_WL,1"
      ];


      /* -- Window Rules -- */
      windowrulev2 = [
        # xwayland screen sharing
        "opacity 0.0 override 0.0 override,class:^(xwaylandvideobridge)$"
        "noanim,class:^(xwaylandvideobridge)$"
        "nofocus,class:^(xwaylandvideobridge)$"
        "noinitialfocus,class:^(xwaylandvideobridge)$"
      ];


      /* -- Look & Feel -- */
      general = {
        gaps_in = 3;
        gaps_out = 0;
        border_size = 2;

        layout = "dwindle";
      };

      dwindle = {
        pseudotile = true; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
        preserve_split = true; #without this the wm will rearrange windows when resizing a window
        force_split = 2; # always split to right/bottom
      };

      decoration = {
        blur = {
            enabled = true;
            size = 3;
            passes = 1;
            new_optimizations = true;
        };
        rounding = 5;
        drop_shadow = true;
        shadow_range = 4;
        shadow_render_power = 3;
      };

      animations = {
        enabled = true;

        #default animations
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 5, myBezier "
          "windowsOut, 1, 5, default, popin 80%"
          "border, 1, 7, default"
          "borderangle, 1, 5, default"
          "fade, 1, 5, default"
          "workspaces, 1, 5, default"
        ];
      };

      xwayland.force_zero_scaling = true;

      /* -- Input & Bindings -- */
      input = {
        kb_layout = "de";
        follow_mouse = 1;
        touchpad.natural_scroll = true;
        sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
        tablet.output = "eDP-1";
      };

      gestures.workspace_swipe = true;

      binds.allow_workspace_cycles = true; #previous now cycles between last two used workspaces (alt+tab behaviour)

      "$mainMod" = "SUPER";
      "$screenshotDir" = "/home/julian/Pictures/Screenshots";

      #regular bindings
      bind = [
        #essential application shortcuts
        "$mainMod, RETURN, exec, alacritty"
        "$mainMod, A, exec, dolphin"
        "$mainMod, D, exec, rofi -show drun"
        "$mainMod, C, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"
        "$mainMod SHIFT, C, exec, cliphist wipe"

        #basic stuff
        "$mainMod SHIFT, Q, killactive,"
        "$mainMod SHIFT, E, exit,"
        "$mainMod SHIFT, SPACE, togglefloating,"
        "$mainMod, T, pseudo, # dwindle"
        "$mainMod, V, togglesplit, # dwindle"
        "$mainMod, F, fullscreen "

        # Move focus (with mainMod + arrow keys + vim keys)
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"
        "$mainMod, H, movefocus, l"
        "$mainMod, L, movefocus, r"
        "$mainMod, K, movefocus, u"
        "$mainMod, J, movefocus, d"

        # Switch workspaces (with TAB)
        "ALT, TAB, workspace, previous"
        "$mainMod, TAB, workspace, e+1"
        "$mainMod SHIFT, TAB, workspace, e-1"

        # Switch workspaces (with mainMod + Scroll (mouse))
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"

        # Move active window (with mainMod + SHIFT + vim keys)
        "$mainMod SHIFT, left, movewindow, l"
        "$mainMod SHIFT, right, movewindow, r"
        "$mainMod SHIFT, up, movewindow, u"
        "$mainMod SHIFT, down, movewindow, d"
        "$mainMod SHIFT, H, movewindow, l"
        "$mainMod SHIFT, L, movewindow, r"
        "$mainMod SHIFT, K, movewindow, u"
        "$mainMod SHIFT, J, movewindow, d"

        # Move workspace (multi monitor)
        "$mainMod ALT, left, movecurrentworkspacetomonitor, l"
        "$mainMod ALT, right, movecurrentworkspacetomonitor, r"
        "$mainMod ALT, H, movecurrentworkspacetomonitor, l"
        "$mainMod ALT, L, movecurrentworkspacetomonitor, r"

        # screenshot (print: active window, framework key/scroll lock (laptop/docked): area. With mainmod: copysave, Without: copy)
        ", Print, exec, grimblast --notify copy active "
        "$mainMod, Print, exec, grimblast --notify copysave active \"$screenshotDir/$(date +\"%Y%m%d_%T\")-Screenshot-active.png\""
        ", Scroll_Lock, exec, grimblast --notify --freeze copy area"
        ", XF86AudioMedia, exec, grimblast --notify --freeze copy area"
        "$mainMod, Scroll_Lock, exec, grimblast --notify --freeze copysave area \"$screenshotDir/$(date +\"%Y%m%d_%T\")-Screenshot-area.png\""
        "$mainMod, XF86AudioMedia, exec, grimblast --notify --freeze copysave area \"$screenshotDir/$(date +\"%Y%m%d_%T\")-Screenshot-area.png\""

        #hyprpicker 
        "ALT, Print, exec, hyprpicker -a -r"

        # hyprctl kill 
        "$mainMod, X, exec, hyprctl kill"

        # lock
        "$mainMod, Y, exec, swaylock -f -c 000000 -i $lock_bg"

        #monitor script: has to be SUPER + P since the multi-monitor key on the framework laptop triggers exactly that combination
        "SUPER, P, exec, rofi -show output -modes \"output:~/.systemScripts/hyprland_output_options.py\""
      ] ++ (
        # generate workspace keybindings since they are very repetitive
        builtins.concatLists (builtins.genList (
          x: let
            ws = let
              c = (x + 1) / 10;
            in
              builtins.toString (x + 1 - (c * 10));
          in [
            # Switch workspaces (with mainMod + [0-9])
            "$mainMod, ${ws}, workspace, ${toString (x + 1)}"
            # Move active window to a workspace (with mainMod + SHIFT + [0-9])
            "$mainMod SHIFT, ${ws}, movetoworkspacesilent, ${toString (x + 1)}"
          ]
        )
        10)
      );

      # mouse bindings
      bindm = [
        # Move/resize active window (with mainMod + LMB/RMB and dragging)
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      # bindings that should also work when locked
      bindl = [
        # mute audio/mic
        ", Pause, exec, pactl set-source-mute @DEFAULT_SOURCE@ toggle"
        ", XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle"
        ", XF86AudioMicMute, exec, pactl set-source-mute @DEFAULT_SOURCE@ toggle"

        # lid suspend & lock screen & dpms (Lid Switch)
        ", switch:Lid Switch, exec, /home/julian/.systemScripts/clamshell_mode_hypr.sh $lock_bg"

        # special keys: audio player, power off
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86PowerOff, exec, /home/julian/.systemScripts/lockAndSuspend.sh $lock_bg 1"
      ];

      # bindings that should also work when locked + holding down will repeat key press
      bindle = [
        # audio volume control
        ", XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%"
        ", XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%"

        # screen brightness control
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
      ];
    };

    # inhibitSuspend submap
    extraConfig =''
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
