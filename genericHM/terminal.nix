{ config, pkgs, nixvim, ...}:

{
  imports = [ ./neovim.nix ];

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
      theme = "juanghurtado";
    };

    #environmental variables for zsh session
    sessionVariables = {
      EDITOR = "nvim"; #set neovim as default editor
      GPG_TTY = "$(tty)"; #for ssh yubikey support
    };
  };

  # lf
  programs.lf = {
    enable = true;
    commands = {
      get-mime-type = "%xdg-mime query filetype \"$f\"";
    };
    extraConfig = ''
      set shell zsh
      set icons true
    '';
    keybindings = {
      # Movement
      gd = "cd ~/Documents";
      gD = "cd ~/Downloads";
      gc = "cd ~/.config";
      gu = "cd ~/Nextcloud/Dokumente/Studium";

      # execute current file
      x = "\$\$f";
      X = "!\$f";
    };
  };
  xdg.configFile."lf/icons".source = ./lf-icons;
}
