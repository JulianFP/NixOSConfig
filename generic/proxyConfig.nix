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
        additionalConfig = ''
          redir /.well-known/carddav /remote.php/dav/ 301
          redir /.well-known/caldav /remote.php/dav/ 301
        '';
      };
      "test.partanengroup.de" = { #nextcloud test
        destIP = "10.42.42.150";
        destIPedge = "48.42.1.150";
        destPort = 80;
        additionalConfig = ''
          redir /.well-known/carddav /remote.php/dav/ 301
          redir /.well-known/caldav /remote.php/dav/ 301
        '';
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
