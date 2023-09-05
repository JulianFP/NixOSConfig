# This file is used in setups with secureboot
# For setups without secureboot use systemd-boot.nix instead

{ config, lib, pkgs, inputs, ... }:
{
  # config for bootloader and secure boot (refer to nixos.wiki/wiki/Secure_Boot)
  boot = {
    bootspec.enable = true;
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
