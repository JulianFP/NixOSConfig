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
    inherit (juliansConfig.programs) git gpg lf; #(2) copy these settings without change
    zsh = juliansTerminal.programs.zsh // { #(3) copy this and make some changes
      oh-my-zsh = juliansTerminal.programs.zsh.oh-my-zsh // {
        custom = "$HOME/.ohMyZshCustom";
        theme = "juanghurtado-rootPatch";
      };
      initExtra = ''
        cd /etc/nixos
      '';
    };
    
    ssh = juliansConfig.programs.ssh // {
      extraConfig = ''
        RemoteForward /run/user/0/gnupg/S.gpg-agent /run/user/0/gnupg/S.gpg-agent.extra
        Match host * exec "gpg-connect-agent UPDATESTARTUPTTY /bye"
      '';
    };
  };

  services.gpg-agent = juliansConfig.services.gpg-agent // {
    pinentryFlavor = "tty";
  };

  xdg.configFile = {
    inherit (juliansConfig.xdg.configFile) "lf/icons";
  };

  home.file = {
    inherit (juliansConfig.home.file) ".ssh/id_rsa.pub";
  };

  systemd.user.sessionVariables = {
    inherit (juliansConfig.systemd.user.sessionVariables) SSH_AUTH_SOCK;
  };

  home.file.".ohMyZshCustom/themes/juanghurtado-rootPatch.zsh-theme" = {
    source = ./juanghurtado-rootPatch.zsh-theme;
  };

  home.username = "root";
  home.homeDirectory = "/root";

  home.stateVersion = "23.11";
  programs.home-manager.enable = true;
}
