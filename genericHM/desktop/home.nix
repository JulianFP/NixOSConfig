{ config, pkgs, ... }:

{
  imports = 
    [
      ./packages.nix #Packages and Fonts installed for this user
      ./hyprland.nix #Hyprland stu
      ./mangohud.nix #mangohud config
      ./qt_gtk.nix #qt settings (mainly theming, not handled by stylix yet)
      ./rofi.nix
      ./neovim/neovim.nix
      ./mozilla.nix
    ];

  # direnv
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # additions to git (other stuff defined in genericHM/shell.nix)
  programs.git = {
    signing = {
      key = "Julian Partanen (Yubikey) <julian@partanengroup.de>";
      signByDefault = true;
    };
    ignores = [ #add direnv stuff to global gitignore
      "*.direnv"
      "*.envrc"
    ];
  };

  # lf
  programs.lf = {
    enable = true;
    commands = {
      #if mimetype is set to nvim: opens file inside current terminal, else: opens file in designated application (new window, asynchronous)
      open = ''
        &{{
          mimetype=$(file --brief --dereference --mime-type $f)
          defapp=$(xdg-mime query default $mimetype)
          case "$defapp" in 
          nvim.desktop)
          lf -remote "send $id \$nvim $f"
            ;;
          *)
            xdg-open $f
          esac
        }}
      '';
    };
    extraConfig = ''
      set shell zsh
      set icons true
    '';
    keybindings = {
      # Movement
      "gd" = "cd ~/Documents";
      "gD" = "cd ~/Downloads";
      "gc" = "cd ~/.config";
      "gu" = "cd ~/Nextcloud/Dokumente/Studium";

      # execute current file
      "x" = "\$\$f";
      "X" = "!\$f";

      #open current dir in dolphin
      "<c-a>" = "&{{dolphin --new-window --select \$ &; disown}}";
    };
  };
  xdg.configFile."lf/icons".source = ./lf-icons;

  # set defaultApplications through mime types
  xdg = {
    enable = true;
    systemDirs.data = [ # add flatpak dirs to path
      "/usr/share:/var/lib/flatpak/exports/share"
      "\$HOME/.local/share/flatpak/exports/share"
    ];
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = config.xdg.userDirs.documents;
    };
    mime.enable = false; #set mime apps manually
    mimeApps = {
      enable = true;
      defaultApplications = {
        "application/pdf" = [ "org.kde.okular.desktop" "firefox.desktop" ]; #pdf
        "application/x-xz" = [ "org.kde.ark.desktop" ]; #.tar.xz
        "application/gzip" = [ "org.kde.ark.desktop" ]; #.tar.gz
        "application/zip" = [ "org.kde.ark.desktop" ]; #.zip
        "application/vnd.oasis.opendocument.spreadsheet" = [ "calc.desktop" ]; #.ods
        "application/vnd.oasis.opendocument.text" = [ "writer.desktop" ]; #.odt
        "application/vnd.oasis.opendocument.presentation" = [ "impress.desktop" ]; #.odp
        "text/plain" = [ "nvim.desktop" ];
        "text/x-c" = [ "nvim.desktop" ]; #.cpp
        "text/x-file" = [ "nvim.desktop" ]; #.h
        "text/x-shellscript" = [ "nvim.desktop" ]; #.sh
        "text/x-script.python" = [ "nvim.desktop" ]; #.py
        "text/csv" = [ "calc.desktop" "nvim.desktop" ]; #.csv, .log
        "video/mp4" = [ "mpv.desktop" "vlc.desktop" ]; #.mp4
        "video/webm" = [ "mpv.desktop" "vlc.desktop" ]; #.webm
        "image/png" = [ "org.kde.gwenview.desktop" ]; #.png
        "image/jpeg" = [ "org.kde.gwenview.desktop" ]; #.jpg
        "image/webp" = [ "org.kde.gwenview.desktop" ]; #.webp
        "image/gif" = [ "org.kde.gwenview.desktop" ]; #.gif
        #web browser
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
        "x-scheme-handler/chrome" = [ "firefox.desktop" ];
        "text/html" = [ "firefox.desktop" ];
        "application/x-extension-htm" = [ "firefox.desktop" ];
        "application/x-extension-html" = [ "firefox.desktop" ];
        "application/x-extension-shtml" = [ "firefox.desktop" ];
        "application/x-extension-xhtml" = [ "firefox.desktop" ];
        "application/x-extension-xht" = [ "firefox.desktop" ];
        "application/xhtml+xml" = [ "firefox.desktop" ];
        #thunderbird
        "x-scheme-handler/mailto" = [ "thunderbird.desktop" ];
        "x-scheme-handler/mid" = [ "thunderbird.desktop" ];
        "x-scheme-handler/webcal" = [ "thunderbird.desktop" ];
        "x-scheme-handler/webcals" = [ "thunderbird.desktop" ];
        "application/x-extension-ics" = [ "thunderbird.desktop" ];
        "message/rfc822" = [ "thunderbird.desktop" ];
        "text/calendar" = [ "thunderbird.desktop" ];
      };
    };
  };

  # Mako (notification daemon)
  services.mako =  {
    enable = true;
    borderRadius = 4;
    borderSize = 2;
    height = 300;
    groupBy = "app-name";
    ignoreTimeout = true;
    extraConfig = with pkgs; ''
    on-notify=exec kill -35 $(pidof waybar)
    on-button-left=exec ${mako}/bin/makoctl invoke -n "$id" && ${mako}/bin/makoctl dismiss -n "$id" && kill -35 $(pidof waybar)
    on-button-right=exec ${mako}/bin/makoctl dismiss -n "$id" && kill -35 $(pidof waybar)

    [app-name="shutdown-reminder"]
    layer=overlay
    on-notify=exec kill -35 $(pidof waybar) && ${mpv}/bin/mpv ${sound-theme-freedesktop}/share/sounds/freedesktop/stereo/dialog-warning.oga

    [mode=doNotDisturb]
    invisible=1
    '';
  };

  # Waybar
  stylix.targets.waybar.enable = false; #my styling is better...
  programs.waybar  = {
    enable = true;
    systemd = {
      enable = true;
      target = "hyprland-session.target";
    };
    settings = import ./waybar/config.nix;
    style = (import ./waybar/style.nix) { config=config; };
  };
  xdg.configFile."mako.sh" = {
    target = "waybar/scripts/mako.sh";
    source = ./systemScripts/makoWaybar.sh;
    executable = true;
  };
  home.file = {
    "launch.sh" = {
      target = ".systemScripts/launch.sh";
      source = ./systemScripts/launch.sh;
      executable = true;
    };
  };

  programs.mpv = {
    enable = true;
    config = {
      profile = "gpu-hq";
      hwdec = "auto-safe";
      vo = "gpu";
      gpu-context = "wayland";
    };
  };

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-gstreamer
      obs-vaapi
      obs-pipewire-audio-capture
    ];
  };

  # Alacritty
  programs.alacritty = {
    enable = true;
    settings.keyboard.bindings = [
      {
        key = "Return";
        mods = "Control";
        action = "SpawnNewInstance";
      }
    ];
  };

  # virt-manager stu. See NixOS Wiki for more
  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };

  #more programs
  programs = {
    chromium.enable = true;
    htop = {
      enable = true;
      package = pkgs.htop-vim;
    };
  };


  /* -- misc -- */
  # Signal start in tray fix
  home.file.".local/share/applications/signal-desktop.desktop".text = ''
    [Desktop Entry]
    Name=Signal
    Exec=env LANGUAGE="en-US:de-DE" ${pkgs.signal-desktop}/bin/signal-desktop --no-sandbox --start-in-tray %U
    Terminal=false
    Type=Application
    Icon=signal-desktop
    StartupWMClass=Signal
    Comment=Private messaging from your desktop
    MimeType=x-scheme-handler/sgnl;x-scheme-handler/signalcaptcha;
    Categories=Network;InstantMessaging;Chat;
  '';

  #shutdown reminder timer and service
  home.file."shutdownReminder.sh" = {
    target = ".systemScripts/shutdownReminder.sh";
    text = ''
      #!/usr/bin/env bash
      currentTime=$(date +%H:%M)
      currentDay=$(date +%Y%m%d)
      logFile="/home/julian/shutdownFailures.log"
      logFileModifyDay=$(date +%Y%m%d -r "$logFile")
      if [[ ! "$currentTime" < "00:00" ]] && [[ "$currentTime" < "00:15" ]]; then
          if [[ "$logFileModifyDay" != "$currentDay" ]]; then
              date >> "$logFile"
          fi
          currentMinute=$(date +%M)
          minuteDiff=$((15-currentMinute))
          notify-send -u critical -a "shutdown-reminder" "  Shutdown Reminder " "The system will shut down in ~$minuteDiff minutes 󱈸󱈸󱈸"
      fi
    '';
    executable = true;
  };
  systemd.user = {
    timers."shutdown-reminder" = {
      Install.WantedBy = [ "timers.target" ];
      Timer.OnCalendar = "*-*-* 00:00:00";
    };
    services."shutdown-reminder" = {
      Service = {
        ExecStart = "/home/julian/.systemScripts/shutdownReminder.sh";
        Type = "oneshot";
      };
      #this is specifically for when I dismiss the notification and stop the shutdown.timer, but then reboot within the 15 min timeframe and forget to do that again and my system just shuts down. Sounds unlikely, happened to my multiple times though.
      Unit.After = [ "graphical-session.target" ];
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
