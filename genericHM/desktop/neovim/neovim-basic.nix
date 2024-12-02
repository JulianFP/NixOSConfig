{ ... }:

# this is the absolute minimum on top of ../../commonNeovim.nix
{
  programs.nixvim = {
    #clipboard support
    clipboard = {
      register = "unnamedplus";
      providers.wl-copy.enable = true;
    };
  };
}
