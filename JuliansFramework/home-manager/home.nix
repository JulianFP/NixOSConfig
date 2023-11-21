{ config, pkgs, ... }:

{
  imports = 
    [
      ./packages.nix #Packages and Fonts installed for this user
      ./hyprland.nix #Hyprland stuff
      ./mangohud.nix #mangohud config
    ];

  # lf
  programs.lf = {
    enable = true;
    commands = {
      get-mime-type = "%xdg-mime query filetype \"$f\"";
    };
    extraConfig = ''
      set shell zsh
      set icons true
    '';
    keybindings = {
      # Movement
      gd = "cd ~/Documents";
      gD = "cd ~/Downloads";
      gc = "cd ~/.config";
      gu = "cd ~/Nextcloud/Dokumente/Studium";

      # execute current file
      x = "\$\$f";
      X = "!\$f";
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
  services.mako = {
    enable = true;
    backgroundColor = "#2B303B9A";
    borderRadius = 4;
    borderSize = 2;
    font = "'Roboto Mono Medium' 12";
    height = 300;
    extraConfig = ''
    [urgency=low]
    border-color=#CCCCCCFF
    
    [urgency=normal]
    border-color=#D08770FF

    [urgency=high]
    border-color=#BF616AFF
    '';
  };

  # Rofi (application starter and more)
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    theme = "gruvbox-dark-soft";
    terminal = "\${pkgs.alacritty}/bin/alacritty";
    font = "Roboto Mono Medium 14";
  };

  # Waybar
  programs.waybar  = {
    enable = true;
    settings = import ./waybar/config.nix;
    style = ./waybar/style.css;
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
    ];
  };

  # Alacritty
  programs.alacritty = {
    enable = true;
    settings = {
      # Colors (Gruvbox Material Medium Dark)
      colors = {
        # Default colors
        primary = {
          background = "#282828";
          foreground = "#d4be98";
        };
        # Normal colors
        normal = {
          black = "#3c3836";
          red = "#ea6962";
          green = "#a9b665";
          yellow = "#d8a657";
          blue = "#7daea3";
          magenta = "#d3869b";
          cyan = "#89b482";
          white = "#d4be98";
        };
        # Bright colors (same as normal colors)
        bright = {
          black = "#3c3836";
          red = "#ea6962";
          green = "#a9b665";
          yellow = "#d8a657";
          blue = "#7daea3";
          magenta = "#d3869b";
          cyan = "#89b482";
          white = "#d4be98";
        };
      };
      font = {
        normal = {
          family = "AnonymicePro Nerd Font";
          style = "Regular";
        };
        size = 12;
      };
      key_bindings = [
        {
          key = "Return";
          mods = "Super|Shift";
          action = "SpawnNewInstance";
        }
      ];
    };
  };

  # virt-manager stuff. See NixOS Wiki for more
  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };

  # Theming
  xdg.configFile = {
    "Kvantum/kvantum.kvconfig".text = ''
      [General]
      theme=MateriaDark
    '';
    "Kvantum/MateriaDark" = {
      source = "${pkgs.materia-kde-theme}/share/Kvantum/MateriaDark";
      recursive = true;
    };
    "qt5ct/qss/fixes.qss".text = ''
      QTabBar::tab:selected {
          color: palette(bright-text);
      }
      QScrollBar {
          background: palette(dark);
      }
      QScrollBar::handle {
          background: palette(highlight);
          border-radius: 4px;
      }
      QScrollBar::add-line, QScrollBar::sub-line {
          background: palette(window);
      }
    '';
    "qt5ct/qt5ct.conf".text = ''
      [Appearance]
      icon_theme=Papirus-Dark
      style=kvantum-dark

      [Interface]
      stylesheets=${config.home.homeDirectory}/.config/qt5ct/qss/fixes.qss
    '';
    "qt6ct/qt6ct.conf".text = ''
      [Appearance]
      icon_theme=Papirus-Dark
      style=kvantum-dark

      [Interface]
      stylesheets=${pkgs.qt6Packages.qt6ct}/share/qt6ct/qss/fusion-fixes.qss
    '';
    "kdeglobals".text = ''
      [General]
      TerminalApplication=alacritty

      [Colors:View]
      BackgroundNormal=#272727

      [KFileDialog Settings]
      Automatically select filename extension=true
      Show Bookmarks=true
      Show Full Path=true
      Show hidden files=true
      Sort by=name
      Sort directories first=false
      View Style=DetailTree
    '';
  };
  gtk = {
    enable = true;
    theme.package = pkgs.materia-theme;
    theme.name = "Materia-dark-compact";
    iconTheme.package = pkgs.papirus-icon-theme;
    iconTheme.name = "Papirus-Dark";
  };
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.capitaine-cursors;
    name = "capitaine-cursors";
    size = 24;
  };

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
