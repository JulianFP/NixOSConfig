{ lib, config, hostName, ... }:

# My Nextcloud server was down because of hardware issues. I was using Syncthing temporarily as a replacement. Keeping this file around in case something similar happens again
{
  sops.secrets = {
    "syncthing/${hostName}.crt" = {
      sopsFile = ../../secrets/${hostName}/syncthing.yaml;
      owner = config.services.syncthing.user;
      group = config.services.syncthing.group;
    };
    "syncthing/${hostName}.key" = {
      sopsFile = ../../secrets/${hostName}/syncthing.yaml;
      owner = config.services.syncthing.user;
      group = config.services.syncthing.group;
    };
  };

  services.syncthing = {
    enable = true;
    
    #all sync directories are for this user anyway
    user = "julian";
    group = "users";
    dataDir = "/home/julian/.syncthing";

    openDefaultPorts = true;

    cert = config.sops.secrets."syncthing/${hostName}.crt".path;
    key = config.sops.secrets."syncthing/${hostName}.key".path;

    settings = {
      gui = {
        user = "julian";
        password = "Trash-80";
      };
      options.urAccepted = -1;

      devices = {
        "JuliansFramework" = lib.mkIf (hostName != "JuliansFramework") {
          id = "DZIA5TH-75ACZ5J-464XX7R-PJEGIHJ-42OQKY7-KET6WLR-7NL2G7L-Z3LMRAE";
          autoAcceptFolders = true;
        };
        "JuliansPC" = lib.mkIf (hostName != "JuliansPC") {
          id = "6GNKOOA-M3DJ5BN-3OUGE6G-VHERO65-L3KA4FZ-GAVYMDL-NTHR5ED-2PWJPAC";
          autoAcceptFolders = true;
        };
        "JuliansPixel6a" = {
          id = "II3AFT7-HL3XT22-S7CBVEK-63UFQ67-WJEMWR6-VCNK6XA-C3CIU7M-RNPFGQH";
          autoAcceptFolders = true;
        };
      };

      folders = {
        "Nextcloud" = {
          path = "/home/julian/Nextcloud";
          versioning = {
            type = "simple";
            params.keep = "10";
          };
          devices = [ "JuliansPixel6a" ]
          ++ lib.lists.optional (hostName != "JuliansFramework") "JuliansFramework"
          ++ lib.lists.optional (hostName != "JuliansPC") "JuliansPC";
        };
        "Camera-Pixel6a" = {
          id = "pixel_6a_wvqg-photos";
          path = "/home/julian/Pictures/Camera-Pixel6a";
          versioning = {
            type = "simple";
            params.keep = "10";
          };
          devices = [ ]
          ++ lib.lists.optional (hostName != "JuliansFramework") "JuliansFramework"
          ++ lib.lists.optional (hostName != "JuliansPC") "JuliansPC";
        };
      };
    };
  };

  systemd.services.syncthing.environment.STNODEFAULTFOLDER = "true"; # Don't create default ~/Sync folder

  services.nebula.networks."serverNetwork".firewall.inbound = [
    {
      port = "22000";
      proto = "tcp";
      group = "julian";
    }
    {
      port = "22000";
      proto = "udp";
      group = "julian";
    }
    {
      port = "21027";
      proto = "udp";
      group = "julian";
    }
  ];
}
