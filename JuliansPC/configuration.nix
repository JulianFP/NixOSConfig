{ config, ... }:

{
  imports = [
    ./hardware-configuration.nix # Include the results of the hardware scan.
    ../generic/ssh.nix
  ];

  # -- Networking --
  networking = {
    useDHCP = false; # overwrite default. See networkd config below
    enableIPv6 = true;
    interfaces."enp14s0".wakeOnLan.enable = true; # enable wake-on-lan

    #manage main lan interface through systemd-networkd instead of networkmanager so that it is declarative and also available in initrd
    networkmanager.unmanaged = [ "enp14s0" ];
  };

  systemd.network = {
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

  # Star Citizen stuff
  /*
    I also needed to add pl_pit.forceSoftwareCursor = 1 to the user.cfg file of the star citizen installation.
    This needs to be done manually and is not handled by this nix derivation.
    See https://wiki.starcitizen-lug.org/Troubleshooting/unexpected-behavior#mousecursor-warp-issues-and-view-snapping-in-interaction-mode for more info
  */
  nix.settings = {
    substituters = [ "https://nix-citizen.cachix.org" ];
    trusted-public-keys = [ "nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo=" ];
  };
  programs.rsi-launcher = {
    enable = true;
    enforceWaylandDrv = true;
    preCommands = ''
      #to fix keyboard layout issues with wine wayland (https://bugs.winehq.org/show_bug.cgi?id=57097):
      export LC_ALL=de
    '';
  };
  services.udev.extraRules = ''
    KERNEL=="hidraw*", ATTRS{idVendor}=="044f", ATTRS{idProduct}=="b10a", MODE="0666", TAG+="uaccess"
  '';

  #for running jobs remotely
  programs.tmux = {
    enable = true;
    clock24 = true;
  };
}
