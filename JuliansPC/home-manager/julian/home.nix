{ ... }:

{
  imports = [
    ./packages.nix
    ./hyprland.nix
  ];

  programs.mangohud.enable = true;
}
