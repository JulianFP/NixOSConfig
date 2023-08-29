{ config, pkgs, ... }:

{
  #Activates ability to install fonts through home-manager
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    wl-clipboard
    cliphist
    playerctl
    brightnessctl
    pulseaudio
    swaylock
    sway-contrib.grimshot
    gnome.adwaita-icon-theme
    tree
    unzip
    pavucontrol
    htop-vim
    s-tui
    networkmanagerapplet
    firefox
    thunderbird
    keepassxc
    libsForQt5.ark
    libsForQt5.dolphin
    libsForQt5.filelight
    libsForQt5.qtstyleplugin-kvantum
    libsForQt5.polkit-kde-agent
    libsForQt5.kwalletmanager
    libsForQt5.kwallet
    libsForQt5.okular
    qt6Packages.qtstyleplugin-kvantum
    nextcloud-client
    signal-desktop
    wineWowPackages.stagingFull
    winetricks
    gamescope
    gamemode
    steam
    lutris
    webcord
    heroic
    texlive.combined.scheme-full

    # Fonts
    roboto-mono
    font-awesome
    nerdfonts
  ];
}
