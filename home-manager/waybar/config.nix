{
  mainBar = {
    layer = "top";
    position = "top";
    height = 30;
    spacing = 4;
    modules-left = [ "hyprland/workspaces" "hyprland/submap" "hyprland/window" ]; 
    modules-right = [ "tray" "gamemode" "pulseaudio" "network" "bluetooth" "cpu" "memory" "temperature" "backlight" "battery" "clock" ];

    "hyprland/workspaces" = {
      sort-by-number = true;
      on-click = "activate";
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
      timezone = "Europe/Berlin";
      tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
      format-alt = "{:%Y-%m-%d}";
    };

    "cpu" = {
      format = "{usage}% ";
      tooltip = false;
      on-click = "alacritty -e htop";
    };

    "memory" = {
      format = "{}% ";
      on-click = "alacritty -e htop";
    };

    "temperature" = {
      critical-threshold = 80;
      format = "{temperatureC}°C {icon}";
      format-icons = ["" "" ""];
    };

    "backlight" = {
      format = "{percent}% {icon}";
      format-icons = ["" "" "" "" "" "" "" "" ""];
    };

    "battery" = {
      states = {
        warning = 30;
	critical = 15;
      };
      format = "{capacity}% {icon}";
      format-charging = "{capacity}% ";
      format-plugged = "{capacity}% ";
      format-alt = "{time} {icon}";
      format-icons = ["" "" "" "" ""];
    };

    "network" = {
      format-wifi = "{essid} ({signalStrength}%) ";
      format-ethernet = "{ipaddr}/{cidr} ";
      tooltip-format = "{ifname} via {gwaddr} ";
      format-linked = "{ifname} (No IP) ";
      format-disconnected = "Disconnected ⚠";
      format-alt = "{ifname}: {ipaddr}/{cidr}";
      on-click-right = "alacritty -e nmtui";
      on-click-middle = "nm-connection-editor";
    };

    "pulseaudio" = {
      format = "{volume}% {icon} {format_source}";
      format-bluetooth = "{volume}% {icon} {format_source}";
      format-bluetooth-muted = " {icon} {format_source}";
      format-muted = " {format_source}";
      format-source = "{volume}% ";
      format-source-muted = "";
      format-icons = {
        headphones = "";
	hands-free = "";
        headset = "";
	phone = "";
	portable = "";
	car = "";
	default = ["" "" ""];
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
      glyph = "";
      hide-not-running = true;
      use-icon = true;
      icon-name = "input-gaming-symbolic";
      icon-spacing = 4;
      icon-size = 20;
      tooltip = true;
      tooltip-format = "Games running: {count}";
    };
  };
}
