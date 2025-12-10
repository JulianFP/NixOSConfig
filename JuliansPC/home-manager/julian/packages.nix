{
  pkgs,
  nix-gaming,
  ...
}:

let
  /*
    I also needed to add pl_pit.forceSoftwareCursor = 1 to the user.cfg file of the star citizen installation.
    This needs to be done manually and is not handled by this nix derivation.
    See https://wiki.starcitizen-lug.org/Troubleshooting/unexpected-behavior#mousecursor-warp-issues-and-view-snapping-in-interaction-mode for more info
  */
  writeScriptBinWrapper =
    name: text:
    (pkgs.writeShellScriptBin name ''
      #to activate wine wayland:
      export DISPLAY=
      #to fix keyboard layout issues with wine wayland (https://bugs.winehq.org/show_bug.cgi?id=57097):
      export LC_ALL=de
      #then execute actual star-citizen script:
      ${text}
    '');
  star-citizen = nix-gaming.packages.${pkgs.stdenv.hostPlatform.system}.star-citizen.override (prev: {
    writeShellScriptBin = writeScriptBinWrapper;
  });
in
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
    star-citizen
    superTuxKart
    prismlauncher
  ];
}
