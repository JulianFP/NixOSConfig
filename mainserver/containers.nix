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
        openTCPPorts = [ 8096 5055 ];
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
    };
  };
}
