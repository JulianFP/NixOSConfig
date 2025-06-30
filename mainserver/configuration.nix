{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./containers.nix
    ./unbound.nix
    ./monitoring.nix
    ../generic/impermanence.nix
    ../generic/proxyConfig.nix
  ];

  programs.tmux = {
    enable = true;
    clock24 = true;
  };

  environment.systemPackages = with pkgs; [ age ];

  #networking config
  networking = {
    useDHCP = false;
    enableIPv6 = false;
    #to access Kanidm using it's domain over local container ip
    hosts."10.42.42.137" = [ "account.partanengroup.de" ];
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

  #Reverse Proxy config
  myModules.proxy = {
    enable = true;
    localDNS = {
      enable = true;
      localForwardIP = "192.168.3.10";
    };
  };

  #nebula extend network
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  networking.nftables = {
    enable = true;
    tables = {
      "nebula_server-network" = {
        family = "ip";
        content = ''
          chain postrouting {
            type nat hook postrouting priority srcnat; policy accept;
            ip saddr 48.42.0.0/16 ip daddr 192.168.3.0/24 counter masquerade
          }

          chain forward {
            type filter hook forward priority filter; policy accept;
            ct state related,established counter accept
            iifname nebula1 oifname enp6s0 ip saddr 48.42.0.0/16 ip daddr 192.168.3.0/24 counter accept
          }
        '';
      };
      "nebula_container-network" = {
        family = "ip";
        content = ''
          chain postrouting {
            type nat hook postrouting priority srcnat; policy accept;
            ip saddr 48.42.0.0/16 ip daddr 10.42.42.0/24 counter masquerade
          }

          chain forward {
            type filter hook forward priority filter; policy accept;
            ct state related,established counter accept
            iifname nebula1 oifname enp6s0 ip saddr 48.42.0.0/16 ip daddr 10.42.42.0/24 counter accept
          }
        '';
      };
    };
  };

  #zfs config
  environment.persistence."/persist".files = [
    "/etc/zfs/zpool.cache" # see nixos manual
  ];
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.extraPools = [ "newData" ];
  networking.hostId = "39c10fc6"; # see option description

  #set nebula preferred_ranges
  services.nebula.networks."serverNetwork".settings.preferred_ranges = [ "192.168.3.0/24" ];

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
