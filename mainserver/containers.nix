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
          "/var/lib/mysql" = {
            hostPath = "/persist/Nextcloud/mysql";
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
            hostPath = "/persist/Nextcloud-Testing/backMeUpData";
            isReadOnly = false;
          };
          "/var/lib/mysql" = {
            hostPath = "/persist/Nextcloud-Testing/mysql";
            isReadOnly = false;
          };
          "/mnt/cloudData/nextcloud" = {
            hostPath = "/persist/Nextcloud-Testing/cloudData";
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
          "/var/lib/postgresql" = {
            hostPath = "/persist/HomeAssistant/postgresql";
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
        nebulaGateway = "48.42.0.5";
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
        nebulaGateway = "48.42.0.5";
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
      "Kanidm" = {
        hostID = 137;
        openTCPPorts = [
          443
          3636
        ];
        enableSops = true;
        additionalBindMounts = {
          "/var/lib/acme" = {
            hostPath = "/persist/Kanidm-acme";
            isReadOnly = false;
          };
          "/var/lib/kanidm" = {
            hostPath = "/persist/backMeUp/Kanidm";
            isReadOnly = false;
          };
        };
        config = ./kanidm/configuration.nix;
      };
      "Email" = {
        hostID = 138;
        openTCPPorts = [
          25 # SMTP
          80 # ACME challenge
          #110 #POP3 STARTTLS, enable if enablePop3 is set in snm
          143 # IMAP STARTTLS
          443 # HTTPS for roundcube and rspamd UI
          465 # SMTP TLS
          587 # SMTP STARTTLS
          993 # IMAP TLS
          #995 #POP3 TLS, enable if enablePop3Ssl is set in snm
          #4190 #sieve, enable if enableManageSieve is set in snm
        ];
        nebulaGateway = "48.42.0.1";
        enableSops = true;
        additionalBindMounts = {
          "/var/lib/acme" = {
            hostPath = "/persist/Email/acme";
            isReadOnly = false;
          };
          "/var/lib/rspamd" = {
            hostPath = "/persist/Email/rspamd";
            isReadOnly = false;
          };
          "/var/lib/postgresql" = {
            hostPath = "/persist/Email/roundcube";
            isReadOnly = false;
          };
          "/persist/backMeUp" = {
            hostPath = "/persist/backMeUp/Email";
            isReadOnly = false;
          };
        };
        config = ./email/configuration.nix;
      };
    };
  };
}
