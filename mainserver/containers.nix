{ ... }:

{
  imports = [
    ../generic/containerModule.nix
  ];

  myModules.container = {
    externalNetworkInterface = "enp0s25";
    containers = {
      "Nextcloud" = {
        hostID = 131;
        openTCPPorts = [ 80 ];
        enableSops = true;
        additionalBindMounts = {
          "/persist/backMeUp" = {
            hostPath = "/persist/backMeUp/Nextcloud";
            isReadOnly = false;
          };
          "/mnt/cloudData/nextcloud" = {
            hostPath = "/newData/Nextcloud";
            isReadOnly = false;
          };
        };
        config = ./nextcloud/configuration.nix;
      };
      "Nextcloud-Testing" = {
        hostID = 150;
        openTCPPorts = [ 80 ];
        enableSops = true;
        additionalBindMounts = {
          "/persist/backMeUp" = {
            hostPath = "/persist/Nextcloud-Testing";
            isReadOnly = false;
          };
          "/mnt/cloudData/nextcloud" = {
            hostPath = "/persist/Nextcloud-Testing_cloudData";
            isReadOnly = false;
          };
        };
        config = ./nextcloud/configuration.nix;
      };
      "Jellyfin" = {
        hostID = 132;
        openTCPPorts = [
          8096
          5055
        ];
        additionalBindMounts = {
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
      };
      "FoundryVTT" = {
        hostID = 133;
        openTCPPorts = [ 30000 ];
        additionalBindMounts = {
          "/persist/backMeUp" = {
            hostPath = "/persist/backMeUp/FoundryVTT";
            isReadOnly = false;
          };
        };
        config = ./foundryvtt/configuration.nix;
      };
      "HomeAssistant" = {
        hostID = 134;
        openTCPPorts = [ 8123 ];
        additionalContainerConfig.allowedDevices = [
          {
            modifier = "rw";
            node = "/dev/ttyUSB0";
          }
        ];
        additionalBindMounts = {
          "/dev_host" = {
            hostPath = "/dev";
            isReadOnly = false;
          };
          "/persist/backMeUp" = {
            hostPath = "/persist/backMeUp/HomeAssistant";
            isReadOnly = false;
          };
        };
        config = ./home-assistant/configuration.nix;
      };
      "ValheimMarvin" = {
        hostID = 135;
        openUDPPorts = [
          2456
          2457
        ];
        nebulaOnly = true;
        enableSops = true;
        permittedUnfreePackages = [
          "steamcmd"
          "steam-unwrapped"
        ];
        additionalBindMounts = {
          "/var/lib/steam" = {
            hostPath = "/persist/ValheimMarvin";
            isReadOnly = false;
          };
          "/persist/backMeUp" = {
            hostPath = "/persist/backMeUp/ValheimMarvin";
            isReadOnly = false;
          };
        };
        config = ./valheim-marvin/configuration.nix;
      };
      "ValheimBrueder" = {
        hostID = 136;
        openUDPPorts = [
          2458
          2459
        ];
        nebulaOnly = true;
        enableSops = true;
        permittedUnfreePackages = [
          "steamcmd"
          "steam-unwrapped"
        ];
        additionalBindMounts = {
          "/var/lib/steam" = {
            hostPath = "/persist/ValheimBrueder";
            isReadOnly = false;
          };
          "/persist/backMeUp" = {
            hostPath = "/persist/backMeUp/ValheimBrueder";
            isReadOnly = false;
          };
        };
        config = ./valheim-brueder/configuration.nix;
      };
    };
  };
}
