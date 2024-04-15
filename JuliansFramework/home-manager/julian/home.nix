{ config, pkgs, nix-colors, ... }:

{
  imports = 
    [
      nix-colors.homeManagerModules.default
      ./packages.nix #Packages and Fonts installed for this user
      ./hyprland.nix #Hyprland stu
      ./mangohud.nix #mangohud config
      ./qt_gtk.nix #qt + gtk settings (mainly theming)
      ./rofi.nix
      ./neovim.nix
    ];



  #define global color scheme here. This gets applied to everything automatically
  colorScheme = nix-colors.colorSchemes.gruvbox-material-dark-medium;
  


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
      };
    };
  };

  # Mako (notification daemon)
  services.mako = with config.colorScheme.palette; {
    enable = true;
    backgroundColor = "#${base01}";
    borderRadius = 4;
    borderSize = 2;
    font = "'Roboto Mono Medium' 12";
    height = 300;
    extraConfig = with pkgs; ''
    on-notify=exec kill -35 $(pidof waybar)
    on-button-left=exec ${mako}/bin/makoctl invoke -n "$id" && ${mako}/bin/makoctl dismiss -n "$id" && kill -35 $(pidof waybar)
    on-button-right=exec ${mako}/bin/makoctl dismiss -n "$id" && kill -35 $(pidof waybar)

    [urgency=low]
    border-color=#${base05}
    
    [urgency=normal]
    border-color=#${base0C}

    [urgency=high]
    border-color=#${base08}

    [mode=doNotDisturb]
    invisible=1
    '';
  };

  # Waybar
  programs.waybar  = {
    enable = true;
    settings = import ./waybar/config.nix;
    style = (import ./waybar/style.nix) { config=config; nix-colors=nix-colors; };
  };
  xdg.configFile."mako.sh" = {
    target = "waybar/scripts/mako.sh";
    source = ./systemScripts/makoWaybar.sh;
    executable = true;
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
    settings = {
      #base16 template: https://github.com/aarowill/base16-alacritty
      colors = with config.colorScheme.palette; {
        # Default colors
        primary = {
          background = "0x${base00}";
          foreground = "0x${base05}";
        };
        # colors the cursor will use if 'custom_cursor_colors' is true
        cursor = {
          text = "0x${base00}";
          cursor = "0x${base05}";
        };
        # Normal colors
        normal = {
          black = "0x${base00}";
          red = "0x${base08}";
          green = "0x${base0B}";
          yellow = "0x${base0A}";
          blue = "0x${base0D}";
          magenta = "0x${base0E}";
          cyan = "0x${base0C}";
          white = "0x${base05}";
        };
        # Bright colors
        bright = {
          black = "0x${base03}";
          red = "0x${base08}";
          green = "0x${base0B}";
          yellow = "0x${base0A}";
          blue = "0x${base0D}";
          magenta = "0x${base0E}";
          cyan = "0x${base0C}";
          white = "0x${base07}";
        };
        indexed_colors = [
          {
            index = 16;
            color = "0x${base09}";
          }
          {
            index = 17;
            color = "0x${base0F}";
          }
          {
            index = 18;
            color = "0x${base01}";
          }
          {
            index = 19;
            color = "0x${base02}";
          }
          {
            index = 20;
            color = "0x${base04}";
          }
          {
            index = 21;
            color = "0x${base06}";
          }
        ];
      };
      font = {
        normal = {
          family = "AnonymicePro Nerd Font";
          style = "Regular";
        };
        size = 12;
      };
      keyboard.bindings = [
        {
          key = "Return";
          mods = "Control";
          action = "SpawnNewInstance";
        }
      ];
    };
  };

  # virt-manager stu. See NixOS Wiki for more
  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };


  /* -- misc -- */
  # Signal start in tray fix
  home.file.".local/share/applications/signal-desktop.desktop".text = ''
[Desktop Entry]
Name=Signal
Exec=${pkgs.signal-desktop}/bin/signal-desktop --no-sandbox --start-in-tray %U
Terminal=false
Type=Application
Icon=signal-desktop
StartupWMClass=Signal
Comment=Private messaging from your desktop
MimeType=x-scheme-handler/sgnl;x-scheme-handler/signalcaptcha;
Categories=Network;InstantMessaging;Chat;
  '';
}
