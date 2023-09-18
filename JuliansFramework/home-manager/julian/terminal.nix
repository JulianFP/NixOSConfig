{ config, pkgs, ... }:

{
  #zsh
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    shellAliases = { #set vi and vim as aliases for neovim
      vi = "nvim";
      vim = "nvim";
      sudo = "sudo "; #https://askubuntu.com/questions/22037/aliases-not-available-when-using-sudo
      config = "cd /etc/nixos/JuliansFramework/ && sudo -s";
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

  # Alacritty
  programs.alacritty = {
    enable = true;
    settings = {
      # Colors (Gruvbox Material Medium Dark)
      colors = {
        # Default colors
        primary = {
          background = "#282828";
          foreground = "#d4be98";
        };
        # Normal colors
        normal = {
          black = "#3c3836";
          red = "#ea6962";
          green = "#a9b665";
          yellow = "#d8a657";
          blue = "#7daea3";
          magenta = "#d3869b";
          cyan = "#89b482";
          white = "#d4be98";
        };
        # Bright colors (same as normal colors)
        bright = {
          black = "#3c3836";
          red = "#ea6962";
          green = "#a9b665";
          yellow = "#d8a657";
          blue = "#7daea3";
          magenta = "#d3869b";
          cyan = "#89b482";
          white = "#d4be98";
        };
      };
      font = {
        normal = {
          family = "AnonymicePro Nerd Font";
          style = "Regular";
        };
        size = 12;
      };
      key_bindings = [
        {
          key = "Return";
          mods = "Super|Shift";
          action = "SpawnNewInstance";
        }
      ];
    };
  };
}
