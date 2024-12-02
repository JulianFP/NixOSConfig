{ pkgs, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix")
  ];

  #for latest bcachefs support in case I need to rescue the system
  environment.systemPackages = [ pkgs.keyutils ];
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    supportedFilesystems = {
      bcachefs = true;
      zfs = lib.mkForce false; #usually not compatible with testing kernel yet
    };
  };
}
