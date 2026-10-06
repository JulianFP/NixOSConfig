{ config, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../generic/impermanence.nix
    ../generic/restic.nix
    ./tang.nix
  ];

  sops.secrets = {
    "users/root" = {
      neededForUsers = true;
      sopsFile = ../secrets/backupServerOffsite/users.yaml;
    };
    "wifi" = {
      sopsFile = ../secrets/backupServerOffsite/wifi.yaml;
      owner = "wpa_supplicant";
      group = "wpa_supplicant";
    };
  };

  # set a password for a root user as a fallback if there is no networking
  users.users.root.hashedPasswordFile = config.sops.secrets."users/root".path;

  #networking config
  networking = {
    useDHCP = false;
    wireless = {
      enable = true;
      interfaces = [ "wlp1s0" ];
      extraConfig = ''
        freq_list=2412 2417 2422 2427 2432 2437 2442 2447 2452 2457 2462 2467 2472 2484
      '';
      secretsFile = config.sops.secrets."wifi".path;
      networks."WGLan".pskRaw = "ext:psk_wglan";
    };
  };
  systemd.network = {
    enable = true;
    networks."10-WGLan" = {
      name = "wlp1s0";
      DHCP = "no";
      networkConfig.IPv6AcceptRA = true;
      address = [
        "192.168.0.30/24"
      ];
      gateway = [
        "192.168.0.1"
      ];
      dns = [
        "1.1.1.1"
        "1.0.0.1"
        "8.8.8.8"
      ];
    };
  };

  myModules.nebula."serverNetwork".unsafeRoutes."wlp1s0" = [ "192.168.0.0/24" ];

  #auto-mount backup HDD
  fileSystems."/mnt/backupHDD" = {
    device = "/dev/disk/by-label/backupHDD2";
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
