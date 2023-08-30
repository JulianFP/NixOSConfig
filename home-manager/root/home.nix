{ config, pkgs, nixvim, ... }:

let
  # I will inherit most of the config from user julian to avoid duplicate code
  # I will do this in three different ways (marked with (1),(2),(3))
  juliansConfig = import ../julian/home.nix {config=config; pkgs=pkgs; nixvim=nixvim;};
  juliansTerminal = import ../julian/terminal.nix {config=config; pkgs=pkgs;};
in {
  imports = [
    nixvim.homeManagerModules.nixvim #import nixvim module
    ./../julian/neovim.nix #(1) import all settings from this file without change
  ];

  programs = {
    inherit (juliansConfig.programs) git; #(2) copy these settings without change
    zsh = juliansTerminal.programs.zsh // { #(3) copy this and make some changes
      oh-my-zsh = juliansTerminal.programs.zsh.oh-my-zsh // {
        custom = "$HOME/.ohMyZshCustom";
        theme = "juanghurtado-rootPatch";
      };
    };
  };

  home.file.".ohMyZshCustom/themes/juanghurtado-rootPatch.zsh-theme" = {
    source = ./juanghurtado-rootPatch.zsh-theme;
  };

  home.username = "root";
  home.homeDirectory = "/root";

  home.stateVersion = "23.11";
  programs.home-manager.enable = true;
}
