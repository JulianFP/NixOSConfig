{ config, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../generic/impermanence.nix
    ../generic/restic.nix
  ];

  # set a password for a root user as a fallback if there is no networking
  sops.secrets."users/root" = {
    neededForUsers = true;
    sopsFile = ../secrets/backupServer/users.yaml;
  };
  users.users.root.hashedPasswordFile = config.sops.secrets."users/root".path;

  #networking config
  networking = {
    useDHCP = false;
  };
  systemd.network = {
    enable = true;
    networks."10-serverLAN" = {
      name = "eno1";
      DHCP = "no";
      networkConfig.IPv6AcceptRA = true;
      address = [
        "192.168.3.30/24"
      ];
      gateway = [
        "192.168.3.1"
      ];
      dns = [
        "1.1.1.1"
        "1.0.0.1"
        "8.8.8.8"
      ];
    };
  };

  myModules.nebula."serverNetwork".unsafeRoutes."eno1" = [ "192.168.3.0/24" ];

  #auto-mount backup HDD
  fileSystems."/mnt/backupHDD" = {
    device = "/dev/disk/by-label/backupHDD1";
    fsType = "btrfs";
    options = [
      "nofail"
      "subvol=restic"
    ];
  };

  #automatic garbage collect and nix store optimisation is done in server.nix
  #automatic upgrade. Pulls newest commits from github daily. Relies on my updating the flake inputs (I want that to be manual and tracked by git)
  system.autoUpgrade = {
    enable = false; # TODO
    flake = "github:JulianFP/NixOSConfig";
    dates = "04:00";
    randomizedDelaySec = "30min";
    allowReboot = true;
    rebootWindow = {
      lower = "04:00";
      upper = "05:00";
    };
  };
}
