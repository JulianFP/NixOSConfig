{ userName, ... }:

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
      custom = if userName == "root" then "$HOME/.ohMyZshCustom" else "";
      theme = if userName == "root" then "juanghurtado-rootPatch" else "juanghurtado";
    };

    #environmental variables for zsh session
    sessionVariables = {
      EDITOR = "nvim"; #set neovim as default editor
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
    enable = if userName == "root" then true else false;
    source = ./juanghurtado-rootPatch.zsh-theme;
  };
}
