{ config, inputs, ... }:

{
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
  };
  services.nebula.networks."serverNetwork".firewall.inbound = [
    {
      port = "80";
      proto = "tcp";
      group = "edge";
    }
  ];

}
