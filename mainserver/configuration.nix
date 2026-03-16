{ pkgs, config, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./containers.nix
    ./unbound.nix
    ./monitoring.nix
    ./backup.nix
    ../generic/impermanence.nix
    ../generic/proxyConfig.nix
  ];

  # set a password for a root user as a fallback if there is no networking
  sops.secrets."users/root" = {
    neededForUsers = true;
    sopsFile = ../secrets/mainserver/users.yaml;
  };
  users.users.root.hashedPasswordFile = config.sops.secrets."users/root".path;

  programs.tmux = {
    enable = true;
    clock24 = true;
  };

  environment.systemPackages = with pkgs; [ age ];

  #networking config
  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks."10-serverLAN" = {
      name = "enp0*";
      DHCP = "no";
      networkConfig.IPv6AcceptRA = true;
      addresses = [
        {
          Address = "192.168.3.10/24";
        }
        {
          #this is an Ionos IP that I own and have a static route in place so that it points to this server
          Address = "2a02:247a:23e:d300:0:4000:0:1/128";
          PreferredLifetime = 0; # dont use for outgoing connections
        }
      ];
      address = [

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

  #Reverse Proxy config
  myModules.proxy = {
    enable = true;
    localDNS = {
      enable = true;
      localForwardIPv4 = "192.168.3.10";
      localForwardIPv6 = "2a02:247a:23e:d300:0:4000:0:1";
    };
  };

  #zfs & btrfs config
  environment.persistence."/persist".files = [
    "/etc/zfs/zpool.cache" # see nixos manual
  ];
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.extraPools = [ "newData" ];
  services.zfs.autoScrub = {
    enable = true;
    interval = "weekly";
  };
  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/" ];
    interval = "weekly";
  };

  networking.hostId = "39c10fc6"; # see option description

  myModules.nebula."serverNetwork".unsafeRoutes = {
    "enp0s25" = [ "192.168.3.0/24" ];
    "br0" = [ "10.42.42.0/24" ];
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
