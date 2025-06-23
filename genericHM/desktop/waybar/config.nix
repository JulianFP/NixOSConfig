{ pkgs }:
{
  mainBar = {
    layer = "top";
    position = "top";
    height = 30;
    spacing = 4;
    modules-left = [
      "hyprland/workspaces"
      "hyprland/submap"
      "hyprland/window"
    ];
    modules-right = [
      "tray"
      "gamemode"
      "custom/mako"
      "pulseaudio"
      "network"
      "bluetooth"
      "cpu"
      "memory"
      "temperature"
      "backlight"
      "battery"
      "clock"
    ];

    "hyprland/workspaces" = {
      sort-by-number = true;
      on-click = "activate";
      format-icons = {
        urgent = "󰂚";
      };
    };

    "hyprland/window" = {
      max-length = 200;
      seperate-outputs = true;
    };

    "hyprland/submap" = {
      format = "<span style=\"italic\">{}</span>";
    };

    "keyboard-state" = {
      numlock = true;
      capslock = true;
      format = "{name} {icon}";
      format-icons = {
        locked = "";
        unlocked = "";
      };
    };

    "tray" = {
      spacing = 10;
    };

    "clock" = {
      tooltip-format = "<big>{:%B %Y}</big><tt><small>{calendar}</small></tt>";
      format-alt = "{:%Y-%m-%d}";
      calendar = {
        format = {
          months = "";
          days = "<span>{}</span>";
          weeks = "<span>W{}</span>";
          weekdays = "<span>{}</span>";
          today = "<span><b><u>{}</u></b></span>";
        };
      };
    };

    "cpu" = {
      format = "{usage}% ";
      tooltip = false;
      on-click = "alacritty -e htop --sort-key=PERCENT_CPU";
    };

    "memory" = {
      format = "{}% ";
      on-click = "alacritty -e htop --sort-key=PERCENT_MEM";
    };

    "temperature" = {
      hwmon-path-abs = "/sys/devices/platform/coretemp.0/hwmon";
      input-filename = "temp1_input";
      critical-threshold = 95;
      format = "{temperatureC}°C {icon}";
      format-icons = [
        ""
        ""
        ""
        ""
        ""
      ];
    };

    "backlight" = {
      format = "{percent}% {icon}";
      format-icons = [
        ""
        ""
        ""
        ""
        ""
        ""
        ""
        ""
        ""
      ];
    };

    "battery" = {
      states = {
        warning = 30;
        critical = 15;
      };
      format = "{capacity}% {icon}";
      format-charging = "{capacity}% ";
      format-plugged = "{capacity}% ";
      format-alt = "{time} {icon}";
      format-icons = [
        ""
        ""
        ""
        ""
        ""
      ];
    };

    "network" = {
      format-wifi = "{essid} ({signalStrength}%) {icon}";
      format-icons = [
        "󰤯"
        "󰤟"
        "󰤢"
        "󰤥"
        "󰤨"
      ];
      format-ethernet = "{ipaddr}/{cidr} ";
      tooltip-format = "{ifname} via {gwaddr} ";
      format-linked = "{ifname} (No IP) ";
      format-disconnected = "Disconnected ";
      format-alt = "{ifname}: {ipaddr}/{cidr}";
      on-click-right = "alacritty -e ~/.systemScripts/launch.sh nmtui"; # nmtui renders weirdly without using launch.sh
      on-click-middle = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
    };

    "pulseaudio" = {
      format = "{volume}% {icon} {format_source}";
      format-bluetooth = "{volume}% {icon} {format_source}";
      format-bluetooth-muted = "󰝟 {icon} {format_source}";
      format-muted = "󰝟 {format_source}";
      format-source = "{volume}% ";
      format-source-muted = "";
      format-icons = {
        headphones = "";
        hands-free = "";
        headset = "";
        phone = "";
        portable = "";
        car = "";
        default = [
          ""
          ""
          ""
        ];
      };
      on-click = "pavucontrol";
    };

    "bluetooth" = {
      format = " {status}";
      format-connected = " {device_alias}";
      format-connected-battery = " {device_alias} {device_battery_percentage}%";
      tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
      tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
      tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
      tooltip-format-enumerate-conntected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
      on-click = "alacritty -e bluetoothctl";
    };

    "gamemode" = {
      format = "{glyph}";
      format-alt = "{glyph} {count}";
      glyph = "󰖺";
      hide-not-running = true;
      use-icon = true;
      icon-name = "input-gaming-symbolic";
      icon-spacing = 4;
      icon-size = 20;
      tooltip = true;
      tooltip-format = "Games running: {count}";
    };

    "custom/mako" = rec {
      exec = "~/.config/waybar/scripts/mako.sh";
      return-type = "json";
      #only on-click command sets makoctl mode and sends SIGRTMIN+1
      #SIGRTMIN+1 will then always trigger script execution! This prevents loop where sending the signal triggers sending a signal and so on
      on-click = "if makoctl mode | grep -q doNotDisturb; then makoctl mode -r doNotDisturb; else makoctl mode -a doNotDisturb; fi; kill -35 $(pidof waybar)";
      #right and middle click will only send SIGRTMIN+1
      on-click-right = "kill -35 $(pidof waybar)";
      on-click-middle = on-click-right;
      tooltip = true;
      interval = "once";
      signal = 1;
      exec-on-event = true;
    };
  };
}
