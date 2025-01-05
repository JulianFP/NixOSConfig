{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../generic/impermanence.nix
  ];

  #networking config
  networking = {
    useDHCP = false;
    enableIPv6 = false;
  };
  systemd.network = {
    enable = true;
    networks."10-serverLAN" = {
      name = "enp0*";
      DHCP = "no";
      networkConfig.IPv6AcceptRA = false;
      address = [
        "192.168.3.10/24"
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

  #zfs config
  environment.persistence."/persist".files = [
    "/etc/zfs/zpool.cache" #see nixos manual
  ];
  boot.supportedFilesystems = [ "zfs" ];
  networking.hostId = "39c10fc6"; #see option description

  #set nebula preferred_ranges
  services.nebula.networks."serverNetwork".settings.preferred_ranges = [ "192.168.3.0/24" ];

  #automatic garbage collect and nix store optimisation is done in server.nix
  #automatic upgrade. Pulls newest commits from github daily. Relies on my updating the flake inputs (I want that to be manual and tracked by git)
  system.autoUpgrade = {
    enable = true;
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
