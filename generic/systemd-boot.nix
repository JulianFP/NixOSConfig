# This file is only used in setups without secureboot
# For secureboot setups use lanzaboote.nix instead

{ ... }:
{
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
}
