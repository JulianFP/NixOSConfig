{ config, inputs, ... }:

{
  #the containers get their own private network instead of a bridge for now
  networking = {
    nftables.enable = true; #make sure again that we really use nftables because of below
    nat = {
      enable = true;
      internalInterfaces = ["ve-*"]; #the * wildcard syntax is specific to nftables, use + if switching back to iptables!
      externalInterface = "enp0s25";
      enableIPv6 = false;
    };
  };
  
  systemd.tmpfiles.settings."10-nextcloud" = {
    "/persist/sops-nix/Nextcloud"."d" = {
      user = "root";
      group = "root";
      mode = "0755";
    };
    "/persist/backMeUp/Nextcloud"."d" = {
      user = "root";
      group = "root";
      mode = "0755";
    };
    "/persist/sops-nix/Nextcloud-Testing"."d" = {
      user = "root";
      group = "root";
      mode = "0755";
    };
    "/persist/Nextcloud-Testing"."d" = {
      user = "root";
      group = "root";
      mode = "0755";
    };
    "/persist/Nextcloud-Testing_cloudData"."d" = {
      user = "root";
      group = "root";
      mode = "0755";
    };
  };
  containers = {
    "Nextcloud-Testing" = {
      autoStart = true;
      ephemeral = true;

      privateNetwork = true;
      hostAddress = "10.42.42.1";
      localAddress = "10.42.42.150";

      bindMounts = {
        "/mnt/cloudData/nextcloud" = {
          hostPath = "/persist/Nextcloud-Testing_cloudData";
          isReadOnly = false;
        };
        "/persist/backMeUp" = {
          hostPath = "/persist/Nextcloud-Testing";
          isReadOnly = false;
        };
        "/persist/sops-nix" = {
          hostPath = "/persist/sops-nix/Nextcloud-Testing";
          isReadOnly = false;
        };
      };

      config = ./nextcloud/configuration.nix;
      specialArgs = {
        hostName = "Nextcloud-Testing";
        stateVersion = config.system.stateVersion;
        inputs = inputs;
      };
    };
    "Nextcloud" = {
      autoStart = true;
      ephemeral = true;

      privateNetwork = true;
      hostAddress = "10.42.42.1";
      localAddress = "10.42.42.131";

      bindMounts = {
        "/mnt/cloudData/nextcloud" = {
          hostPath = "/newData/Nextcloud";
          isReadOnly = false;
        };
        "/persist/backMeUp" = {
          hostPath = "/persist/backMeUp/Nextcloud";
          isReadOnly = false;
        };
        "/persist/sops-nix" = {
          hostPath = "/persist/sops-nix/Nextcloud";
          isReadOnly = false;
        };
      };

      config = ./nextcloud/configuration.nix;
      specialArgs = {
        hostName = "Nextcloud";
        stateVersion = config.system.stateVersion;
        inputs = inputs;
      };
    };
    "Jellyfin" = {
      autoStart = true;
      ephemeral = true;

      privateNetwork = true;
      hostAddress = "10.42.42.1";
      localAddress = "10.42.42.132";

      bindMounts = {
        "/mnt/mediadata" = {
          hostPath = "/newData/Jellyfin";
          isReadOnly = false;
        };
        "/persist/jellyfin" = {
          hostPath = "/persist/Jellyfin";
          isReadOnly = false;
        };
        "/var/lib/jellyfin" = {
          hostPath = "/persist/backMeUp/Jellyfin/var/lib/jellyfin";
          isReadOnly = false;
        };
        "/var/lib/private/jellyseerr" = {
          hostPath = "/persist/backMeUp/Jellyfin/var/lib/private/jellyseerr";
          isReadOnly = false;
        };
      };

      config = ./jellyfin/configuration.nix;
      specialArgs = {
        hostName = "Jellyfin";
        stateVersion = config.system.stateVersion;
        inputs = inputs;
      };
    };
  };
  services.nebula.networks."serverNetwork".firewall.inbound = [
    { #Nextcloud, Nextcloud-Testing
      port = "80";
      proto = "tcp";
      group = "edge";
    }
    { #Jellyfin: Jellyfin
      port = "8096";
      proto = "tcp";
      group = "edge";
    }
    { #Jellyfin: Jellyseerr
      port = "5055";
      proto = "tcp";
      group = "edge";
    }
  ];

}
