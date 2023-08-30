{ config, pkgs, nixvim, ... }:

{
  imports = 
    [
      nixvim.homeManagerModules.nixvim #import nixvim module
      ./packages.nix #Packages and Fonts installed for this user
      ./hyprland.nix #Hyprland stuff
      ./terminal.nix #Terminal stuff (Alacritty, zsh, ...) 
      ./neovim.nix #Neovim stuff
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
  qt = {
    enable = true;
    platformTheme = "qtct";
  };
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
