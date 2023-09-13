{ config, pkgs, ... }:

{
  #Activates ability to install fonts through home-manager
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    # Hyprland additions, desktop stuff
    wl-clipboard
    cliphist
    playerctl
    brightnessctl
    pulseaudio
    pavucontrol
    networkmanagerapplet
    libsForQt5.polkit-kde-agent
    libsForQt5.kwalletmanager
    libsForQt5.kwallet
    swaylock
    sway-contrib.grimshot
    gnome.adwaita-icon-theme
    nur.repos.mikilio.xwaylandvideobridge-hypr

    # CLI Applications
    tree
    unzip
    htop-vim
    s-tui
    amdgpu_top

    # Applications
    firefox
    thunderbird
    libreoffice-fresh
    xournalpp
    logseq
    keepassxc
    nextcloud-client
    signal-desktop
    webcord
    libsForQt5.ark
    libsForQt5.dolphin
    libsForQt5.filelight
    libsForQt5.okular
    yubioath-flutter
    yubikey-manager-qt

    # Multimedia
    libsForQt5.gwenview
    libsForQt5.kimageformats
    libsForQt5.qt5.qtimageformats
    vlc
    freetube

    # Gaming
    wineWowPackages.stagingFull
    winetricks
    gamescope
    gamemode
    lutris
    heroic
    protonup-qt

    # Development
    texlive.combined.scheme-full
    gcc
    cmake
    gnumake
    valgrind

    # Fonts
    roboto-mono
    font-awesome
    nerdfonts
  ];
}
