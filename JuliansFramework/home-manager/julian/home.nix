{ config, pkgs, inputs, ... }:

let 
  nix-colors = inputs.nix-colors;
  nix-colors-lib = nix-colors.lib.contrib { inherit pkgs; };
in
{
  imports = 
    [
      nix-colors.homeManagerModules.default
      ./packages.nix #Packages and Fonts installed for this user
      ./hyprland.nix #Hyprland stu
      ./mangohud.nix #mangohud config
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
    border-color=#CCCCCC
    
    [urgency=normal]
    border-color=#D08770

    [urgency=high]
    border-color=#BF616A

    [mode=doNotDisturb]
    invisible=1
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
      colors = with config.colorScheme.colors; {
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
          mods = "Super|Shift";
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

  /* -- gui theming -- */
  qt = {
    enable = true;
    platformTheme = "kde";
  };

  #inspired by https://github.com/Base24/base16-kdeplasma
  xdg.configFile."kdeglobals".text = with config.colorScheme.colors; with nix-colors.lib.conversions; ''
    [ColorEffects:Disabled]
    ChangeSelectionColor=
    Color=56,56,56
    ColorAmount=1
    ColorEffect=0
    ContrastAmount=0.5
    ContrastEffect=1
    Enable=
    IntensityAmount=0
    IntensityEffect=2

    [ColorEffects:Inactive]
    ChangeSelectionColor=true
    Color=112,111,110
    ColorAmount=-0.9500000000000001
    ColorEffect=0
    ContrastAmount=0.6000000000000001
    ContrastEffect=0
    Enable=false
    IntensityAmount=0
    IntensityEffect=0

    [Colors:Button]
    BackgroundAlternate=${hexToRGBString "," base01}
    BackgroundNormal=${hexToRGBString "," base00}
    DecorationFocus=${hexToRGBString "," base08}
    DecorationHover=${hexToRGBString "," base08}
    ForegroundActive=${hexToRGBString "," base0B}
    ForegroundInactive=${hexToRGBString "," base05}
    ForegroundLink=${hexToRGBString "," base0D}
    ForegroundNegative=${hexToRGBString "," base0F}
    ForegroundNeutral=${hexToRGBString "," base04}
    ForegroundNormal=${hexToRGBString "," base05}
    ForegroundPositive=${hexToRGBString "," base0C}
    ForegroundVisited=${hexToRGBString "," base0E}

    [Colors:Selection]
    BackgroundAlternate=${hexToRGBString "," base08}
    BackgroundNormal=${hexToRGBString "," base08}
    DecorationFocus=${hexToRGBString "," base08}
    DecorationHover=${hexToRGBString "," base08}
    ForegroundActive=${hexToRGBString "," base0B}
    ForegroundInactive=${hexToRGBString "," base02}
    ForegroundLink=${hexToRGBString "," base0D}
    ForegroundNegative=${hexToRGBString "," base0F}
    ForegroundNeutral=${hexToRGBString "," base04}
    ForegroundNormal=${hexToRGBString "," base02}
    ForegroundPositive=${hexToRGBString "," base0C}
    ForegroundVisited=${hexToRGBString "," base0E}

    [Colors:Tooltip]
    BackgroundAlternate=${hexToRGBString "," base02}
    BackgroundNormal=${hexToRGBString "," base01}
    DecorationFocus=${hexToRGBString "," base08}
    DecorationHover=${hexToRGBString "," base08}
    ForegroundActive=${hexToRGBString "," base0B}
    ForegroundInactive=${hexToRGBString "," base05}
    ForegroundLink=${hexToRGBString "," base0D}
    ForegroundNegative=${hexToRGBString "," base0F}
    ForegroundNeutral=${hexToRGBString "," base04}
    ForegroundNormal=${hexToRGBString "," base05}
    ForegroundPositive=${hexToRGBString "," base0C}
    ForegroundVisited=${hexToRGBString "," base0E}

    [Colors:View]
    BackgroundAlternate=${hexToRGBString "," base02}
    BackgroundNormal=${hexToRGBString "," base01}
    DecorationFocus=${hexToRGBString "," base08}
    DecorationHover=${hexToRGBString "," base08}
    ForegroundActive=${hexToRGBString "," base0B}
    ForegroundInactive=${hexToRGBString "," base05}
    ForegroundLink=${hexToRGBString "," base0D}
    ForegroundNegative=${hexToRGBString "," base0F}
    ForegroundNeutral=${hexToRGBString "," base04}
    ForegroundNormal=${hexToRGBString "," base05}
    ForegroundPositive=${hexToRGBString "," base0C}
    ForegroundVisited=${hexToRGBString "," base0E}

    [Colors:Window]
    BackgroundAlternate=${hexToRGBString "," base01}
    BackgroundNormal=${hexToRGBString "," base00}
    DecorationFocus=${hexToRGBString "," base08}
    DecorationHover=${hexToRGBString "," base08}
    ForegroundActive=${hexToRGBString "," base0B}
    ForegroundInactive=${hexToRGBString "," base05}
    ForegroundLink=${hexToRGBString "," base0D}
    ForegroundNegative=${hexToRGBString "," base0F}
    ForegroundNeutral=${hexToRGBString "," base04}
    ForegroundNormal=${hexToRGBString "," base05}
    ForegroundPositive=${hexToRGBString "," base0C}
    ForegroundVisited=${hexToRGBString "," base0E}

    [General]
    TerminalApplication=alacritty

    [Icons]
    Theme=Papirus-Dark

    [KDE]
    SingleClick=false
    LookAndFeelPackage=org.kde.breezedark.desktop

    [KFileDialog Settings]
    Allow Expansion=false
    Automatically select filename extension=true
    Breadcrumb Navigation=true
    Decoration position=2
    LocationCombo Completionmode=5
    PathCombo Completionmode=5
    Show Bookmarks=true
    Show Full Path=true
    Show Inline Previews=true
    Show Speedbar=true
    Show hidden files=true
    Sort by=Name
    Sort directories first=false
    Sort hidden files last=false
    Sort reversed=false
    Speedbar Width=236
    View Style=DetailTree

    [WM]
    activeBackground=${hexToRGBString "," base00}
    activeBlend=${hexToRGBString "," base00}
    activeForeground=${hexToRGBString "," base05}
    inactiveBackground=${hexToRGBString "," base00}
    inactiveBlend=${hexToRGBString "," base00}
    inactiveForeground=${hexToRGBString "," base04}
  '';

  #gtk theming
  gtk = {
    enable = true;
    theme.package = nix-colors-lib.gtkThemeFromScheme {
      scheme = config.colorScheme;      
    };
    theme.name = config.colorScheme.slug;
    iconTheme.package = pkgs.papirus-icon-theme;
    iconTheme.name = "Papirus-Dark";
  };

  #cursor style
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.capitaine-cursors;
    name = "capitaine-cursors";
    size = 24;
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
