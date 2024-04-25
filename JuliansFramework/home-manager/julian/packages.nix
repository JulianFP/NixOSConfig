{ pkgs, nix-citizen, ... }:

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
    kdePackages.qtsvg #qt6 needs this to load icons
    libsForQt5.kservice #qt5 version needed by dolphin for some reason?
    kdePackages.kwalletmanager
    kdePackages.kwallet
    kdePackages.baloo
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
    chromium
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
    slack
    webcord
    kdePackages.ark
    kdePackages.dolphin
    kdePackages.filelight
    kdePackages.okular
    kdePackages.kcalc
    yubioath-flutter
    yubikey-manager-qt

    # Multimedia
    kdePackages.gwenview
    kdePackages.kimageformats
    kdePackages.qtimageformats
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
    prismlauncher
    nix-citizen.packages.${pkgs.system}.lug-helper

    # Development
    #note: texlive (latex) is installed in neovim config
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
