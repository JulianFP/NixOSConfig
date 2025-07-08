{ config, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../generic/impermanence.nix
    ../generic/restic.nix
    ./tang.nix
  ];

  # set a password for a root user as a fallback if there is no networking
  sops.secrets."users/root" = {
    neededForUsers = true;
    sopsFile = ../secrets/backupServerOffsite/users.yaml;
  };
  users.users.root.hashedPasswordFile = config.sops.secrets."users/root".path;

  #networking config
  networking = {
    useDHCP = false;
  };
  systemd.network = {
    enable = true;
    networks."10-serverLAN" = {
      name = "enp0*";
      DHCP = "no";
      networkConfig.IPv6AcceptRA = true;
      address = [
        "192.168.10.30/24"
      ];
      gateway = [
        "192.168.10.1"
      ];
      dns = [
        "1.1.1.1"
        "1.0.0.1"
        "8.8.8.8"
      ];
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
            ip saddr 48.42.0.0/16 ip daddr 192.168.10.0/24 counter masquerade
          }

          chain forward {
            type filter hook forward priority filter; policy accept;
            ct state related,established counter accept
            iifname nebula1 oifname enp0s4 ip saddr 48.42.0.0/16 ip daddr 192.168.10.0/24 counter accept
          }
        '';
      };
    };
  };

  services.nebula.networks."serverNetwork" = {
    settings.preferred_ranges = [ "192.168.10.0/24" ];
    firewall.inbound = [
      # for access to extended network, i.e. router web interface
      {
        #network forwarding
        port = "any";
        proto = "any";
        group = "admin";
      }
    ];
  };

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
