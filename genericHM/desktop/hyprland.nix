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
    configType = "lua";

    settings =
      let
        mainMod = "SUPER";
        screenshotDir = "/home/julian/Pictures/Screenshots";
        writeBindings =
          binds:
          builtins.map (
            binding:
            let
              last_elem = lib.last binding;
            in
            {
              _args = [
                (builtins.elemAt binding 0)
                (lib.generators.mkLuaInline (builtins.elemAt binding 1))
              ]
              ++ (lib.optional (builtins.isAttrs last_elem) last_elem);
            }
          ) binds;
      in
      {
        config = {
          # -- Look & Feel --
          general = {
            gaps_in = 3;
            gaps_out = 0;
            border_size = 2;

            layout = "dwindle";
          };

          dwindle = {
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

          xwayland.force_zero_scaling = true;

          # -- Input & Bindings --
          input = {
            kb_layout = "de";
            follow_mouse = 1;
            touchpad.natural_scroll = true;
            sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
          };

          binds.allow_workspace_cycles = true; # previous now cycles between last two used workspaces (alt+tab behaviour)

          #setup screencopy permissions
          ecosystem.enforce_permissions = true;
        };

        # -- Window Rules --
        window_rule = [
          #start some apps in their designated workspace
          {
            match.class = "thunderbird";
            workspace = "10 silent";
          }
        ];

        permission = [
          {
            binary = "${pkgs.xdg-desktop-portal-hyprland}/libexec/.xdg-desktop-portal-hyprland-wrapped";
            type = "screencopy";
            mode = "allow";
          }
          {
            binary = "${pkgs.grimblast}/bin/grimblast";
            type = "screencopy";
            mode = "allow";
          }
          {
            binary = "${pkgs.grim}/bin/grim";
            type = "screencopy";
            mode = "allow";
          }
          {
            binary = "${pkgs.hyprpicker}/bin/hyprpicker";
            type = "screencopy";
            mode = "allow";
          }
          {
            binary = "${pkgs.hyprlock}/bin/hyprlock";
            type = "screencopy";
            mode = "allow";
          }
        ];

        curve = [
          {
            _args = [
              "myBezier"
              {
                type = "bezier";
                points = [
                  [
                    0.05
                    0.9
                  ]
                  [
                    0.1
                    1.05
                  ]
                ];
              }
            ];
          }
        ];
        animation = [
          {
            leaf = "windows";
            enabled = true;
            speed = 5;
            bezier = "myBezier";
          }
          {
            leaf = "windowsOut";
            enabled = true;
            speed = 5;
            bezier = "default";
            style = "popin 80%";
          }
          {
            leaf = "border";
            enabled = true;
            speed = 7;
            bezier = "default";
          }
          {
            leaf = "borderangle";
            enabled = true;
            speed = 5;
            bezier = "default";
          }
          {
            leaf = "fade";
            enabled = true;
            speed = 5;
            bezier = "default";
          }
          {
            leaf = "workspaces";
            enabled = true;
            speed = 5;
            bezier = "default";
          }
        ];

        #trackpad gestures
        gesture = [
          {
            fingers = 3;
            direction = "horizontal";
            action = "workspace";
          }
          {
            fingers = 3;
            direction = "vertical";
            action = "fullscreen";
          }
          {
            fingers = 3;
            direction = "pinchout";
            scale = 0.5;
            action = "float";
            mode = "float";
          }
          {
            fingers = 3;
            direction = "pinchin";
            scale = 0.5;
            action = "float";
            mode = "tile";
          }
          {
            fingers = 3;
            direction = "swipe";
            mods = mainMod;
            action = "resize";
          }
        ];

        #regular bindings
        bind = writeBindings (
          [
            #essential application shortcuts
            [
              "${mainMod} + RETURN"
              "hl.dsp.exec_cmd(\"uwsm app -- Alacritty.desktop\")"
            ]
            [
              "${mainMod} + A"
              "hl.dsp.exec_cmd(\"uwsm app -- org.kde.dolphin.desktop\")"
            ]
            [
              "${mainMod} + D"
              "hl.dsp.exec_cmd('rofi -show drun --run-command \"uwsm app -- {cmd}\"')"
            ]
            [
              "${mainMod} + C"
              "hl.dsp.exec_cmd(\"cliphist list | rofi -dmenu | cliphist decode | wl-copy\")"
            ]
            [
              "${mainMod} + SHIFT + C"
              "hl.dsp.exec_cmd(\"cliphist wipe\")"
            ]

            #basic stuff
            [
              "${mainMod} + SHIFT + Q"
              "hl.dsp.window.close()"
            ]
            [
              "${mainMod} + SHIFT + E"
              "hl.dsp.exec_cmd(\"uwsm stop\")"
            ]
            [
              "${mainMod} + SHIFT + SPACE"
              "hl.dsp.window.float()"
            ]
            [
              "${mainMod} + T"
              "hl.dsp.window.pseudo()"
            ] # dwindle
            [
              "${mainMod} + V"
              "hl.dsp.layout(\"togglesplit\")"
            ] # dwindle
            [
              "${mainMod} + F"
              "hl.dsp.window.fullscreen()"
            ]

            # Move focus (with ${mainMod} + arrow keys + vim keys)
            [
              "${mainMod} + left"
              "hl.dsp.focus({ direction=\"l\" })"
            ]
            [
              "${mainMod} + right"
              "hl.dsp.focus({ direction=\"r\" })"
            ]
            [
              "${mainMod} + up"
              "hl.dsp.focus({ direction=\"u\" })"
            ]
            [
              "${mainMod} + down"
              "hl.dsp.focus({ direction=\"d\" })"
            ]
            [
              "${mainMod} + H"
              "hl.dsp.focus({ direction=\"l\" })"
            ]
            [
              "${mainMod} + L"
              "hl.dsp.focus({ direction=\"r\" })"
            ]
            [
              "${mainMod} + K"
              "hl.dsp.focus({ direction=\"u\" })"
            ]
            [
              "${mainMod} + J"
              "hl.dsp.focus({ direction=\"d\" })"
            ]

            # Switch workspaces (with TAB)
            [
              "ALT + TAB"
              "hl.dsp.focus({ workspace=\"previous\" })"
            ]
            [
              "${mainMod} + TAB"
              "hl.dsp.focus({ workspace=\"e+1\" })"
            ]
            [
              "${mainMod} + SHIFT + TAB"
              "hl.dsp.focus({ workspace=\"e-1\" })"
            ]

            # Switch workspaces (with ${mainMod} + Scroll (mouse))
            [
              "${mainMod} + mouse_down"
              "hl.dsp.focus({ workspace=\"e+1\" })"
            ]
            [
              "${mainMod} + mouse_up"
              "hl.dsp.focus({ workspace=\"e-1\" })"
            ]

            # Move active window (with ${mainMod} + SHIFT + vim keys)
            [
              "${mainMod} + SHIFT + left"
              "hl.dsp.window.move({ direction=\"l\" })"
            ]
            [
              "${mainMod} + SHIFT + right"
              "hl.dsp.window.move({ direction=\"r\" })"
            ]
            [
              "${mainMod} + SHIFT + up"
              "hl.dsp.window.move({ direction=\"u\" })"
            ]
            [
              "${mainMod} + SHIFT + down"
              "hl.dsp.window.move({ direction=\"d\" })"
            ]
            [
              "${mainMod} + SHIFT + H"
              "hl.dsp.window.move({ direction=\"l\" })"
            ]
            [
              "${mainMod} + SHIFT + L"
              "hl.dsp.window.move({ direction=\"r\" })"
            ]
            [
              "${mainMod} + SHIFT + K"
              "hl.dsp.window.move({ direction=\"u\" })"
            ]
            [
              "${mainMod} + SHIFT + J"
              "hl.dsp.window.move({ direction=\"d\" })"
            ]

            # Move workspace (multi monitor)
            [
              "${mainMod} + ALT + left"
              "hl.dsp.workspace.move({ monitor=\"l\" })"
            ]
            [
              "${mainMod} + ALT + right"
              "hl.dsp.workspace.move({ monitor=\"r\" })"
            ]
            [
              "${mainMod} + ALT + up"
              "hl.dsp.workspace.move({ monitor=\"u\" })"
            ]
            [
              "${mainMod} + ALT + down"
              "hl.dsp.workspace.move({ monitor=\"d\" })"
            ]
            [
              "${mainMod} + ALT + H"
              "hl.dsp.workspace.move({ monitor=\"l\" })"
            ]
            [
              "${mainMod} + ALT + L"
              "hl.dsp.workspace.move({ monitor=\"r\" })"
            ]
            [
              "${mainMod} + ALT + K"
              "hl.dsp.workspace.move({ monitor=\"u\" })"
            ]
            [
              "${mainMod} + ALT + J"
              "hl.dsp.workspace.move({ monitor=\"d\" })"
            ]

            # screenshot (print: active window, framework key/scroll lock (laptop/docked): area. With ${mainMod}: copysave, Without: copy)
            [
              "Print"
              "hl.dsp.exec_cmd(\"${pkgs.grimblast}/bin/grimblast --notify copy active\")"
            ]
            [
              "${mainMod} + Print"
              "hl.dsp.exec_cmd('${pkgs.grimblast}/bin/grimblast --notify copysave active \"${screenshotDir}/$(date +\"%Y%m%d_%T\")-Screenshot-active.png\"')"
            ]
            [
              "Scroll_Lock"
              "hl.dsp.exec_cmd(\"${pkgs.grimblast}/bin/grimblast --notify --freeze copy area\")"
            ]
            [
              "${mainMod} + Scroll_Lock"
              "hl.dsp.exec_cmd('${pkgs.grimblast}/bin/grimblast --notify --freeze copysave area \"${screenshotDir}/$(date +\"%Y%m%d_%T\")-Screenshot-area.png\"')"
            ]

            #hyprpicker
            [
              "ALT + Print"
              "hl.dsp.exec_cmd(\"${pkgs.hyprpicker}/bin/hyprpicker -a -r\")"
            ]

            # hyprctl kill
            [
              "${mainMod} + X"
              "hl.dsp.exec_cmd(\"hyprctl kill\")"
            ]

            # lock
            [
              "${mainMod} + escape"
              "hl.dsp.exec_cmd(\"hyprlock\")"
            ]

            #monitor script: has to be SUPER + P since the multi-monitor key on the framework laptop triggers exactly that combination
            [
              "SUPER + P"
              "hl.dsp.exec_cmd('rofi -show output -modes \"output:~/.systemScripts/hyprland_output_options.py\"')"
            ]

            # Move/resize active window (with mainMod + LMB/RMB and dragging)
            [
              "${mainMod} + mouse:272"
              "hl.dsp.window.drag()"
              { mouse = true; }
            ]
            [
              "${mainMod} + mouse:273"
              "hl.dsp.window.resize()"
              { mouse = true; }
            ]
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
                  [
                    "${mainMod} + ${ws}"
                    "hl.dsp.focus({ workspace=\"${builtins.toString (x + 1)}\" })"
                  ]
                  # Move active window to a workspace (with mainMod + SHIFT + [0-9])
                  [
                    "${mainMod} + SHIFT + ${ws}"
                    "hl.dsp.window.move({ workspace=\"${builtins.toString (x + 1)}\", follow=false })"
                  ]
                ]
              ) 10
            )
          )
        );
      };

    extraConfig = ''
      function setLockedBindings()
        -- mute audio/mic
        hl.bind("Pause", (hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle")), {["locked"] = true})
        hl.bind("XF86AudioMute", (hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle")), {["locked"] = true})
        hl.bind("XF86AudioMicMute", (hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle")), {["locked"] = true})
        -- lid suspend & lock screen & dpms (Lid Switch)
        hl.bind("switch:[Lid Switch]", (hl.dsp.exec_cmd("/home/julian/.systemScripts/clamshell_mode_hypr.sh")), {["locked"] = true})
        -- special keys: audio player, power off
        hl.bind("XF86AudioPlay", (hl.dsp.exec_cmd("playerctl play-pause")), {["locked"] = true})
        hl.bind("XF86AudioNext", (hl.dsp.exec_cmd("playerctl next")), {["locked"] = true})
        hl.bind("XF86AudioPrev", (hl.dsp.exec_cmd("playerctl previous")), {["locked"] = true})
        hl.bind("XF86PowerOff", (hl.dsp.exec_cmd("/home/julian/.systemScripts/lockAndSuspend.sh 1")), {["locked"] = true})
        -- audio volume control
        hl.bind("XF86AudioRaiseVolume", (hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +5%")), {["locked"] = true,["repeating"] = true})
        hl.bind("XF86AudioLowerVolume", (hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -5%")), {["locked"] = true,["repeating"] = true})
        -- display brightness control
        hl.bind("XF86MonBrightnessDown", (hl.dsp.exec_cmd("brightnessctl set 5%-")), {["locked"] = true,["repeating"] = true})
        hl.bind("XF86MonBrightnessUp", (hl.dsp.exec_cmd("brightnessctl set 5%+")), {["locked"] = true,["repeating"] = true})
      end
      setLockedBindings()
      hl.define_submap("inhibitSuspend", function()
        setLockedBindings()
        hl.bind("escape", (hl.dsp.submap("reset")))
      end)
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
    #set hyprsunset as a blue light filter for the evenings
    hyprsunset = {
      enable = true;
      settings.profile = [
        {
          time = "8:00";
          identity = true;
        }
        {
          time = "22:00";
          temperature = 3500;
        }
      ];
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
        shadow_passes = 2;
        placeholder_text = "<i>UwU :3</i>";
      };
      label = [
        {
          shadow_passes = 2;
          text = "$TIME";
          color = "rgb(${base05})";
          font_size = 100;
          halign = "center";
          valign = "center";
          text_align = "center";
          position = "0, 165";
        }
        {
          shadow_passes = 2;
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
}
