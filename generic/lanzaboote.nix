# This file is used in setups with secureboot
# For setups without secureboot use systemd-boot.nix instead

{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  environment.systemPackages = [ pkgs.sbctl ]; # for debugging and troubleshooting Secure Boot

  # config for bootloader and secure boot (refer to https://wiki.nixos.org/wiki/Secure_Boot)
  boot = {
    loader = {
      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = true;
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
  };
}
