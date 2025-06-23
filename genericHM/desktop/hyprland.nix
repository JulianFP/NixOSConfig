{
  pkgs,
  lib,
  config,
  ...
}:

{
  # set scripts for extended Hyprland behavior (suspend, lock, etc.)
  home.file = {
    "lockAndSuspend.sh" = {
      target = ".systemScripts/lockAndSuspend.sh";
      source = lib.mkDefault ./systemScripts/lockAndSuspend.sh; # can be overwritten by the hibernate equivalent
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

    settings = {
      # -- Window Rules --
      windowrule = [
        #start some apps in their designated workspace
        "workspace 10 silent,class:thunderbird"
        # xwayland screen sharing (xwayland is not autostarted anymore though because I rarely need it)
        "opacity 0.0 override 0.0 override,class:^(xwaylandvideobridge)$"
        "noanim,class:^(xwaylandvideobridge)$"
        "nofocus,class:^(xwaylandvideobridge)$"
        "noinitialfocus,class:^(xwaylandvideobridge)$"
        "noblur,class:^(xwaylandvideobridge)$"
        "maxsize 1 1,class:^(xwaylandvideobridge)$"
      ];

      # -- Look & Feel --
      general = {
        gaps_in = 3;
        gaps_out = 0;
        border_size = 2;

        layout = "dwindle";
      };

      dwindle = {
        pseudotile = true; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
        preserve_split = true; # without this the wm will rearrange windows when resizing a window
        force_split = 2; # always split to right/bottom
      };

      decoration = {
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
          new_optimizations = true;
        };
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
        };
        rounding = 5;
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

      # -- Input & Bindings --
      input = {
        kb_layout = "de";
        follow_mouse = 1;
        touchpad.natural_scroll = true;
        sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
      };

      gestures.workspace_swipe = true;

      binds.allow_workspace_cycles = true; # previous now cycles between last two used workspaces (alt+tab behaviour)

      "$mainMod" = "SUPER";
      "$screenshotDir" = "/home/julian/Pictures/Screenshots";

      #regular bindings
      bind =
        [
          #essential application shortcuts
          "$mainMod, RETURN, exec, uwsm app -- Alacritty.desktop"
          "$mainMod, A, exec, uwsm app -- org.kde.dolphin.desktop"
          "$mainMod, D, exec, rofi -show drun -run-command \"uwsm app -- {cmd}\""
          "$mainMod, C, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"
          "$mainMod SHIFT, C, exec, cliphist wipe"

          #basic stuff
          "$mainMod SHIFT, Q, killactive,"
          "$mainMod SHIFT, E, exec, uwsm stop"
          "$mainMod SHIFT, SPACE, togglefloating,"
          "$mainMod, T, pseudo, # dwindle"
          "$mainMod, V, togglesplit, # dwindle"
          "$mainMod, F, fullscreen,"

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
          ", Print, exec, ${pkgs.grimblast}/bin/grimblast --notify copy active "
          "$mainMod, Print, exec, ${pkgs.grimblast}/bin/grimblast --notify copysave active \"$screenshotDir/$(date +\"%Y%m%d_%T\")-Screenshot-active.png\""
          ", Scroll_Lock, exec, ${pkgs.grimblast}/bin/grimblast --notify --freeze copy area"
          "$mainMod, Scroll_Lock, exec, ${pkgs.grimblast}/bin/grimblast --notify --freeze copysave area \"$screenshotDir/$(date +\"%Y%m%d_%T\")-Screenshot-area.png\""

          #hyprpicker
          "ALT, Print, exec, ${pkgs.hyprpicker}/bin/hyprpicker -a -r"

          # hyprctl kill
          "$mainMod, X, exec, hyprctl kill"

          # lock
          "$mainMod, Y, exec, hyprlock"

          #monitor script: has to be SUPER + P since the multi-monitor key on the framework laptop triggers exactly that combination
          "SUPER, P, exec, rofi -show output -modes \"output:~/.systemScripts/hyprland_output_options.py\""
        ]
        ++ (
          # generate workspace keybindings since they are very repetitive
          builtins.concatLists (
            builtins.genList (
              x:
              let
                ws =
                  let
                    c = (x + 1) / 10;
                  in
                  builtins.toString (x + 1 - (c * 10));
              in
              [
                # Switch workspaces (with mainMod + [0-9])
                "$mainMod, ${ws}, workspace, ${toString (x + 1)}"
                # Move active window to a workspace (with mainMod + SHIFT + [0-9])
                "$mainMod SHIFT, ${ws}, movetoworkspacesilent, ${toString (x + 1)}"
              ]
            ) 10
          )
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
        ", switch:Lid Switch, exec, /home/julian/.systemScripts/clamshell_mode_hypr.sh"

        # special keys: audio player, power off
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86PowerOff, exec, /home/julian/.systemScripts/lockAndSuspend.sh 1"
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

      #setup screencopy permissions
      ecosystem.enforce_permissions = true;
      permission = [
        "${pkgs.xdg-desktop-portal-hyprland}/libexec/.xdg-desktop-portal-hyprland-wrapped, screencopy, allow"
        "${pkgs.grimblast}/bin/grimblast, screencopy, allow"
        "${pkgs.grim}/bin/grim, screencopy, allow"
        "${pkgs.hyprpicker}/bin/hyprpicker, screencopy, allow"
        "${pkgs.hyprlock}/bin/hyprlock, screencopy, allow"
      ];
    };

    # inhibitSuspend submap
    extraConfig = ''
      submap = inhibitSuspend
      bindl = , switch:Lid Switch, exec, /home/julian/.systemScripts/clamshell_mode_hypr.sh inhibitSuspend
      bindle = , XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%
      bindle = , XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%
      bindl = , XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle
      bindl = , XF86AudioMicMute, exec, pactl set-source-mute @DEFAULT_SOURCE@ toggle
      bindle = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
      bindle = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
      bindl = , XF86AudioPlay, exec, playerctl play-pause
      bindl = , XF86AudioNext, exec, playerctl next
      bindl = , XF86AudioPrev, exec, playerctl previous
      bindl = , XF86PowerOff, exec, /home/julian/.systemScripts/lockAndSuspend.sh 1 inhibitSuspend
      bind = ,escape,submap,reset
      submap = reset
    '';
  };

  xdg.configFile."uwsm/env".text = ''
    export QT_QPA_PLATFORM="wayland;xcb"
    export QT_AUTO_SCREEN_SCALE_FACTOR=1
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    export GDK_BACKEND="wayland,x11"
    export CLUTTER_BACKEND=wayland
    export _JAVA_AWT_WM_NONREPARENTING=1
    export NIXOS_OZONE_WL=1
  '';

  programs.zsh.profileExtra = ''
    if uwsm check may-start && uwsm select; then
      exec uwsm start default
    fi
  '';

  services = {
    hyprpaper.enable = true; # configured by stylix
    hyprpolkitagent.enable = true;
    cliphist = {
      enable = true;
      allowImages = true;
    };
  };

  programs.hyprlock = {
    enable = true;
    settings = with config.lib.stylix.colors; {
      general.hide_cursor = true;
      background = {
        path = lib.mkForce "screenshot";
        blur_passes = 3;
      };
      input-field = {
        shadow-passes = 2;
        placeholder_text = "<i>UwU :3</i>";
      };
      label = [
        {
          shadow-passes = 2;
          text = "$TIME";
          color = "rgb(${base05})";
          font_size = 100;
          halign = "center";
          valign = "center";
          text_align = "center";
          position = "0, 165";
        }
        {
          shadow-passes = 2;
          color = "rgb(${base04})";
          text = "cmd[update:30000] echo \"<span>$(fortune -s | sed 's/&/\\&amp;/g; s/</\\&lt;/g; s/>/\\&gt;/g')</span>\"";
          halign = "center";
          valign = "center";
          text_align = "center";
          position = "0, -125";
        }
      ];
    };
  };

  #set hyprsunset as a blue light filter for the evenings
  systemd.user = {
    timers."hyprsunset" = {
      Install.WantedBy = [ "timers.target" ];
      Timer.OnCalendar = "*-*-* 22:30:00";
    };
    services."hyprsunset" = {
      Service.ExecStart = "${pkgs.hyprsunset}/bin/hyprsunset -t 3500";
      Unit.Requisite = [ "graphical-session.target" ];
    };
  };
}
