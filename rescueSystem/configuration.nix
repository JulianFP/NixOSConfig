{ pkgs, lib, modulesPath, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;


  #for latest bcachefs support in case I need to rescue the system
  environment.systemPackages = [ pkgs.keyutils ];
  boot = {
    kernelPackages = pkgs.linuxPackages_testing;
    supportedFilesystems = {
      bcachefs = true;
    };
  };

  services = {
    pipewire = {
      enable = true;
      pulse.enable = true;
    };

    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    desktopManager.plasma6.enable = true;

    # yubikey setup
    udev.packages = [ pkgs.yubikey-personalization ];
    pcscd.enable = true;
  };

  networking.networkmanager.enable = true;

  powerManagement.enable = true;

  # Enable plymouth
  boot.plymouth.enable = true;

  environment.defaultPackages = with pkgs; [
    git
    firefox
    kdePackages.konversation
  ];

  users.users.julian = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "Trash-80";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
