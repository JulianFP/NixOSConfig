{ config, ... }:

# config for some shell stuff shared by julian and root user of JuliansFramework
{
  imports = [ ./commonNeovim.nix ];

  #zsh
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    shellAliases = { #set vi and vim as aliases for neovim
      vi = "nvim";
      vim = "nvim";
      sudo = "sudo "; #https://askubuntu.com/questions/22037/aliases-not-available-when-using-sudo
      root = "machinectl shell --uid 0";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      custom = if config.home.username == "root" then "$HOME/.ohMyZshCustom" else "";
      theme = if config.home.username == "root" then "juanghurtado-rootPatch" else "juanghurtado";
    };

    #environmental variables for zsh session
    sessionVariables = {
      EDITOR = "nvim"; #set neovim as default editor
    };
  };

  #ssh
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "Ionos" = {
        hostname = "82.165.49.241";
        user = "root";
      };
    };
  };

  # git
  programs.git = {
    enable = true;
    userName = "JulianFP";
    userEmail = "julian@partanengroup.de";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  home.file.".ohMyZshCustom/themes/juanghurtado-rootPatch.zsh-theme" = {
    enable = if config.home.username == "root" then true else false;
    source = ./juanghurtado-rootPatch.zsh-theme;
  };
}
