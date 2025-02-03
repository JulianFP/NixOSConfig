{ ... }:

{
  imports = [
    ./proxyModule.nix
  ];

  myModules.proxy = {
    proxies = {
      "partanengroup.de" = { #nextcloud production
        destIP = "10.42.42.131";
        destIPedge = "48.42.1.131";
        destPort = 80;
        additionalLocations = {
          "/.well-known/carddav".return = "301 $scheme://$host/remote.php/dav";
          "/.well-known/caldav".return = "301 $scheme://$host/remote.php/dav";
        };
      };
      "test.partanengroup.de" = { #nextcloud test
        destIP = "10.42.42.150";
        destIPedge = "48.42.1.150";
        destPort = 80;
        additionalLocations = {
          "/.well-known/carddav".return = "301 $scheme://$host/remote.php/dav";
          "/.well-known/caldav".return = "301 $scheme://$host/remote.php/dav";
        };
      };
      "media.partanengroup.de" = { #jellyfin
        destIP = "10.42.42.132";
        destIPedge = "48.42.1.132";
        destPort = 8096;
      };
      "request.media.partanengroup.de" = { #jellyseerr
        destIP = "10.42.42.132";
        destIPedge = "48.42.1.132";
        destPort = 5055;
      };
      "vtt.partanengroup.de" = { #Foundry VTT server
        destIP = "10.42.42.133";
        destIPedge = "48.42.1.133";
        destPort = 30000;
      };
    };
    localProxyHostNames = [
      "mainserver"
    ];
    edgeHostName = "IonosVPS";
  };
}
