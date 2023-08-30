{ config, pkgs, nixvim, ... }:

let
  # inherit most of this config from user julian to avoid duplicate code
  juliansConfig = import ../julian/home.nix {config=config; pkgs=pkgs; nixvim=nixvim;};
  juliansTerminal = import ../julian/terminal.nix {config=config; pkgs=pkgs;};
in {
  programs = {
    inherit (juliansConfig.programs) git; #copy these without changes
    zsh = juliansTerminal.programs.zsh // { #copy this and make some changes
      oh-my-zsh = {
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
