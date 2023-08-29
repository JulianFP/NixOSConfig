{ config, pkgs, ... }:

{
  imports =
    [
      ./terminal.nix #Terminal stuff (same as for julianHome)
    ];

  # git
  programs.git = {
    enable = true;
    userName = "JulianFP";
    userEmail = "julian@partanengroup.de";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  home.username = "root";
  home.homeDirectory = "/root";

  home.stateVersion = "23.11";
  programs.home-manager.enable = true;
}
