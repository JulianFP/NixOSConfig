{ config, ... }:

{
  imports = [
    ./proxyModule.nix
  ];

  myModules.proxy = {
    proxies = {
      "partanengroup.de" = { #nextcloud production
        destIP = "10.42.42.131";
        destIPedge = config.myModules.nebula."serverNetwork".ipMap.Nextcloud;
        destPort = 80;
        additionalConfig = ''
          redir /.well-known/carddav /remote.php/dav/ 301
          redir /.well-known/caldav /remote.php/dav/ 301
        '';
      };
      "test.partanengroup.de" = { #nextcloud test
        destIP = "10.42.42.150";
        destIPedge = config.myModules.nebula."serverNetwork".ipMap.Nextcloud-Testing;
        destPort = 80;
        additionalConfig = ''
          redir /.well-known/carddav /remote.php/dav/ 301
          redir /.well-known/caldav /remote.php/dav/ 301
        '';
      };
      "media.partanengroup.de" = { #jellyfin
        destIP = "10.42.42.132";
        destIPedge = config.myModules.nebula."serverNetwork".ipMap.Jellyfin;
        destPort = 8096;
      };
      "request.media.partanengroup.de" = { #jellyseerr
        destIP = "10.42.42.132";
        destIPedge = config.myModules.nebula."serverNetwork".ipMap.Jellyfin;
        destPort = 5055;
      };
      "vtt.partanengroup.de" = { #Foundry VTT server
        destIP = "10.42.42.133";
        destIPedge = config.myModules.nebula."serverNetwork".ipMap.FoundryVTT;
        destPort = 30000;
      };
      "home.partanengroup.de" = { #Home Assistant
        destIP = "10.42.42.134";
        destIPedge = config.myModules.nebula."serverNetwork".ipMap.HomeAssistant;
        destPort = 8123;
      };
    };
    edgeHostName = "IonosVPS";
  };
}
