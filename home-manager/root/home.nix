{ config, pkgs, ... }:

(import ../julian/home.nix) {
  inherit (programs) git;

  home.username = "root";
  home.homeDirectory = "/root";

  home.stateVersion = "23.11";
  programs.home-manager.enable = true;
}
