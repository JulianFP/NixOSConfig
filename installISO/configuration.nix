{ pkgs, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix")
  ];

  #for latest bcachefs support in case I need to rescue the system
  environment.systemPackages = [ pkgs.keyutils ];
  boot = {
    kernelPackages = pkgs.linuxPackages_testing;
    supportedFilesystems = {
      bcachefs = true;
      zfs = lib.mkForce false; #usually not compatible with testing kernel yet
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
