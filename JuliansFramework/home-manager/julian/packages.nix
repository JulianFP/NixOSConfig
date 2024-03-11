{ pkgs, ... }:

let
  my-python-packages = ps: with ps; [
    numpy
    flask
    openai-whisper 
    httpx
    cookiecutter
  ];
in 
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
    qt5.qtwayland
    qt6.qtwayland
    libsForQt5.breeze-qt5
    libsForQt5.polkit-kde-agent
    libsForQt5.kwalletmanager
    libsForQt5.kwallet
    swaylock
    hyprpicker
    grimblast
    gnome.adwaita-icon-theme
    nur.repos.mikilio.xwaylandvideobridge-hypr


    # CLI Applications
    file #needed for open command of lf
    tree
    unzip
    htop-vim
    s-tui
    amdgpu_top

    # Applications
    firefox
    thunderbird
    libreoffice-qt
    pdfarranger
    hunspell
    hunspellDicts.en_US
    hunspellDicts.de_DE
    xournalpp
    logseq
    keepassxc
    nextcloud-client
    signal-desktop
    element-desktop
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
    gst_all_1.gstreamer
    gst_all_1.gst-vaapi

    # Gaming
    wineWowPackages.stagingFull
    winetricks
    gamescope
    gamemode
    lutris
    heroic
    protonup-qt
    superTuxKart
    prismlauncher-qt5

    # Development
    texlive.combined.scheme-full
    gcc
    cmake
    gnumake
    valgrind
    jetbrains.idea-ultimate
    (python3.withPackages my-python-packages)

    # Fonts
    roboto-mono
    font-awesome
    nerdfonts
    corefonts
    vistafonts
  ];
}
