{ lib, stable, ... }:

# this is a neovim configuration for (pretty much) all my devices & users.
# basic stuff only 
# some devices/users may expand uppon this
{
  programs.nixvim = {
    clipboard = {
      register = "unnamedplus";
      providers.wl-copy.enable = true;
    };
  };
}
