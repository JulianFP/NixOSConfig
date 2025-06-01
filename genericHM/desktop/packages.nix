{ pkgs, ... }:

let
  python-packages = ps: with ps; [
    dbus-python #e.g. eduroam-cat relies on that
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
    #networkmanagerapplet
    qt5.qtwayland
    qt6.qtwayland
    kdePackages.qtsvg #qt6 needs this to load icons
    libsForQt5.kservice #qt5 version needed by dolphin for some reason?
    ripgrep-all
    fortune #for hyprlock
    adwaita-icon-theme
    nur.repos.mikilio.xwaylandvideobridge-hypr

    # CLI Applications
    file #needed for open command of lf
    libnotify #needed for shutdown reminder
    tree
    unzip

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
    signal-desktop-bin #switch to bin version until https://github.com/NixOS/nixpkgs/issues/407967 is resolved
    iamb
    discord
    kdePackages.ark
    kdePackages.dolphin
    kdePackages.filelight
    kdePackages.okular
    kdePackages.kcalc
    yubioath-flutter
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

    # Development
    #note: texlive (latex) is also installed in neovim config
    texlive.combined.scheme-full
    lyx
    gcc
    cmake
    gnumake
    valgrind
    rustup
    jetbrains.idea-ultimate
    arduino-ide
    (python3.withPackages python-packages)

    # Fonts
    roboto-mono
    font-awesome
    nerd-fonts.symbols-only #for waybar
    corefonts
    vistafonts
  ];
}
