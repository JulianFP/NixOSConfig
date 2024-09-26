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
    adwaita-icon-theme
    nur.repos.mikilio.xwaylandvideobridge-hypr


    # CLI Applications
    file #needed for open command of lf
    libnotify #needed for shutdown reminder
    tree
    unzip
    s-tui
    amdgpu_top

    # Applications
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
    (callPackage ./../../../generic/packages/guilded/package.nix {})
    kdePackages.ark
    kdePackages.dolphin
    kdePackages.filelight
    kdePackages.okular
    kdePackages.kcalc
    yubioath-flutter
    yubikey-manager-qt
    seafile-client

    # Multimedia
    kdePackages.gwenview
    kdePackages.kimageformats
    kdePackages.qtimageformats
    vlc
    freetube
    gst_all_1.gstreamer
    gst_all_1.gst-vaapi
    qpwgraph

    # Gaming
    wineWowPackages.stagingFull
    winetricks
    gamescope
    lutris
    heroic
    protonup-qt
    superTuxKart
    prismlauncher
    nix-citizen.packages.${pkgs.system}.lug-helper

    # Development
    #note: texlive (latex) is also installed in neovim config
    texlive.combined.scheme-full
    lyx
    gcc
    cmake
    gnumake
    valgrind
    jetbrains.idea-ultimate
    arduino-ide
    (python3.withPackages my-python-packages)

    # Fonts
    roboto-mono
    font-awesome
    nerdfonts
    corefonts
    vistafonts
  ];
}
