{ pkgs, ... }:

{
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
    superTuxKart
    prismlauncher
  ];
}
