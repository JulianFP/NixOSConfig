{ config, pkgs, nixvim, ... }:

{
  imports = 
    [
      nixvim.homeManagerModules.nixvim #import nixvim module
      ./packages.nix #Packages and Fonts installed for this user
      ./hyprland.nix #Hyprland stuff
      ./terminal.nix #Terminal stuff (Alacritty, zsh, ...) 
      ./neovim.nix #Neovim stuff
      ./mangohud.nix #mangohud config
    ];

  home.username = "julian";
  home.homeDirectory = "/home/julian";

  # ssh (with yubikey support) stuff
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "Ionos" = {
        hostname = "82.165.49.241";
	user = "root";
      };
    };
  };
  home.file.".ssh/id_rsa.pub" = {
    source = ./id_rsa.pub;
  };
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    defaultCacheTtl = 300;
    defaultCacheTtlSsh = 300;
    maxCacheTtl = 3600;
    maxCacheTtlSsh = 3600;
    pinentryFlavor = "qt";
    extraConfig = ''
      ttyname $GPG_TTY
    '';
  };
  programs.gpg = {
    enable = true;
    scdaemonSettings = {
      card-timeout = "300";
      disable-ccid = true;
      pcsc-shared = true;
      reader-port = "Yubico Yubi";
    };
  };
  systemd.user.sessionVariables = {
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh";
  };

  # git
  programs.git = {
    enable = true;
    userName = "JulianFP";
    userEmail = "julian@partanengroup.de";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  # lf
  programs.lf = {
    enable = true;
    commands = {
      get-mime-type = "%xdg-mime query filetype \"$f\"";
      open = "$$OPENER $f";
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

  # Mako
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

  # Rofi
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
    "qt5ct/qt5ct.conf".text = ''
      [Appearance]
      icon_theme=Papirus-Dark
      style=kvantum-dark
    '';
    "qt6ct/qt6ct.conf".text = ''
      [Appearance]
      icon_theme=Papirus-Dark
      style=kvantum-dark
    '';
    "kdeglobals".text = ''
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

  # Signal start in tray fix
  home.file.".local/share/applications/signal-desktop.desktop".text = ''
[Desktop Entry]
Name=Signal
Exec=/nix/store/hn7djii291f7yha9fci3y84vyd5a66yv-signal-desktop-6.27.1/bin/signal-desktop --no-sandbox --start-in-tray %U
Terminal=false
Type=Application
Icon=signal-desktop
StartupWMClass=Signal
Comment=Private messaging from your desktop
MimeType=x-scheme-handler/sgnl;x-scheme-handler/signalcaptcha;
Categories=Network;InstantMessaging;Chat;
  '';

  home.stateVersion = "23.11";
  programs.home-manager.enable = true;
}
