{ pkgs, lib, nix-gaming, ... }:

let
  python-packages = ps: with ps; [
    dbus-python #e.g. eduroam-cat relies on that
  ];

  #fixes gamemode when using omu-launcher. See https://github.com/FeralInteractive/gamemode/issues/254#issuecomment-643648779
  gamemodeSharedObjects = lib.concatMapStringsSep ":" (v: "${lib.getLib pkgs.gamemode}/lib/${v}") [
    "libgamemodeauto.so"
    "libgamemode.so"
  ];

  star-citizen = nix-gaming.packages.${pkgs.system}.star-citizen.override (prev: {
    useUmu = true;
    gameScopeEnable = true;
    gameScopeArgs = [
      "--fullscreen"
      "--mangoapp"
      "--force-grab-cursor"
      "--nested-width=2560"
      "--output-width=2560"
      "--nested-height=1440"
      "--output-height=1440"
      "--force-windows-fullscreen"
      "--rt"
    ];
    preCommands = ''
      export LD_PRELOAD="${gamemodeSharedObjects}"
    '';
  });
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
    iamb
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
    star-citizen
    superTuxKart
    prismlauncher

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
    (python3.withPackages python-packages)

    # Fonts
    roboto-mono
    font-awesome
    nerd-fonts.symbols-only #for waybar
    corefonts
    vistafonts
  ];
}
