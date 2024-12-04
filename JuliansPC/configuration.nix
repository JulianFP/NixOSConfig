{ lib, config, ...}:

{
  imports = [
    ./hardware-configuration.nix # Include the results of the hardware scan.
    ../generic/ssh.nix
  ];

  # Star Citizen tweaks
  boot.kernel.sysctl = {
      "vm.max_map_count" = lib.mkDefault 16777216; #also set by nix-gaming
      "fs.file-max" = 524288;
  };

  #networking setup
  networking = {
    useDHCP = false;
    enableIPv6 = true;
  };
  systemd.network =  {
    enable = true;
    networks."10-enp" = {
      name = "enp*";
      DHCP = "no";
      networkConfig.IPv6AcceptRA = true;
      address = [
        "192.168.10.35/24"
      ];
      gateway = [
        "192.168.10.1"
      ];
      dns = [
        "1.1.1.1"
        "1.0.0.1"
        "2606:4700:4700::1111"
        "2606:4700:4700::1001"
      ];
      linkConfig.RequiredForOnline = "routable";
    };
  };

  #add networking to initrd
  boot.initrd = {
    availableKernelModules = [ "r8169" ];
    systemd.network = {
      enable = true;
      networks = config.systemd.network.networks;
    };
  };

  # enable wake-on-lan
  networking.interfaces."enp14s0".wakeOnLan.enable = true;
}
