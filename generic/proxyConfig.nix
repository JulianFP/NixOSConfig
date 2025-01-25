{ ... }:

{
  imports = [
    ./proxyModule.nix
  ];

  myModules.proxy = {
    proxies = {
      "partanengroup.de" = { #nextcloud production
        destIP = "10.42.42.131";
        destPort = 80;
        additionalLocations = {
          "/.well-known/carddav".return = "301 $scheme://$host/remote.php/dav";
          "/.well-known/caldav".return = "301 $scheme://$host/remote.php/dav";
        };
      };
      "test.partanengroup.de" = { #nextcloud test
        destIP = "10.42.42.150";
        destPort = 80;
        additionalLocations = {
          "/.well-known/carddav".return = "301 $scheme://$host/remote.php/dav";
          "/.well-known/caldav".return = "301 $scheme://$host/remote.php/dav";
        };
      };
      "media.partanengroup.de" = { #jellyfin
        destIP = "10.42.42.132";
        destPort = 8096;
      };
      "request.media.partanengroup.de" = { #jellyseerr
        destIP = "10.42.42.132";
        destPort = 5055;
      };
    };
    localProxyHostNames = [
      "mainserver"
    ];
    edgeHostName = "IonosVPS";
  };
}
