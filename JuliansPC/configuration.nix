{ lib, config, ...}:

{
  imports = [
    ./hardware-configuration.nix # Include the results of the hardware scan.
    ../generic/ssh.nix
  ];

  /* -- Networking -- */
  networking = {
    useDHCP = false; #overwrite default. See networkd config below
    enableIPv6 = true;
    interfaces."enp14s0".wakeOnLan.enable = true; # enable wake-on-lan

    #manage main lan interface through systemd-networkd instead of networkmanager so that it is declarative and also available in initrd
    networkmanager.unmanaged = [ "enp14s0" ];
  };

  systemd.network =  {
    enable = true;
    networks."10-enp" = {
      name = "enp14s0";
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


  # Star Citizen tweaks
  boot.kernel.sysctl = {
      "vm.max_map_count" = lib.mkDefault 16777216; #also set by nix-gaming
      "fs.file-max" = 524288;
  };
  #set the "uaccess" tag for raw HID access for Thrustmaster T.16000M Joystick in wine
  #needed for newer wine/proton versions only (I think wine >= 9.22), disabled for now since I use proton-ge
  /*
  services.udev.extraRules = ''
    KERNEL=="hidraw*", ATTRS{idVendor}=="044f", ATTRS{idProduct}=="b10a", MODE="0666", TAG+="uaccess"
  '';
  */
}
