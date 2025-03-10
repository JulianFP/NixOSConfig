{ pkgs, lib, nix-gaming, ... }:

let
  #fixes gamemode when using omu-launcher. See https://github.com/FeralInteractive/gamemode/issues/254#issuecomment-643648779
  gamemodeSharedObjects = lib.concatMapStringsSep ":" (v: "${lib.getLib pkgs.gamemode}/lib/${v}") [
    "libgamemodeauto.so"
    "libgamemode.so"
  ];

  star-citizen = nix-gaming.packages.${pkgs.system}.star-citizen.override (prev: {
    disableEac = false;
    useUmu = true;
    gameScopeEnable = true;
    gameScopeArgs = [
      "--fullscreen"
      "--force-grab-cursor"
      "--nested-width=2560"
      "--output-width=2560"
      "--nested-height=1440"
      "--output-height=1440"
      "--force-windows-fullscreen"
    ];
    preCommands = ''
      export LD_PRELOAD="${gamemodeSharedObjects}"
    '';
  });
in {
  home.packages = with pkgs; [
    # CLI Applications
    amdgpu_top

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
  ];
}
