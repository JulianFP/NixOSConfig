{ config, pkgs, ... }:

{
  #zsh
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      vi = "nvim";
      vim = "nvim";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "juanghurtado";
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
