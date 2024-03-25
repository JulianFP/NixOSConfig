{ lib, pkgs, edge, ... }:

# This is the setup for all my (reverse) proxies. Currently I have one in the cloud that is exposed to the internet (IonosVPS) and one locally that is not (LocalProxy)
# for the first one edge is set, for the second not. The first one syncs ssl certs to the second one
let
  subnet = if edge then "48.42.1." else "192.168.3.";
in
{
#setup acme for let's encrypt validation if this is on edge
security.acme = lib.mkIf edge {
  acceptTerms = true;
  defaults.email = "admin@partanengroup.de";
  #ssh matchBlock for LocalProxy has to be setup on edge server
  defaults.postRun = ''
    ${pkgs.openssh}/bin/ssh LocalProxy "mkdir -p /var/lib/sslCerts"
    ${pkgs.openssh}/bin/scp -r $(pwd) LocalProxy:/var/lib/sslCerts/
    ${pkgs.openssh}/bin/ssh LocalProxy "chown -R nginx:nginx /var/lib/sslCerts/*"
    ${pkgs.openssh}/bin/ssh LocalProxy "systemctl restart nginx.service"
  '';
};

#LocalProxy can also pull certs from IonosVPS if they are missing (e.g. after reinstall)
systemd.services."pre-nginx" = lib.mkIf (!edge) {
  enable = true;
  script = ''
    mkdir -p /var/lib/sslCerts
    if ! ls -R /var/lib/sslCerts | grep -q "cert.pem"; then
        ${pkgs.openssh}/bin/scp -r IonosVPS:/var/lib/acme/* /var/lib/sslCerts/
        chown -R nginx:nginx /var/lib/sslCerts/*
    fi
  '';
  serviceConfig = {
    Type = "oneshot";
    User = "root";
  };
  wantedBy = [ "nginx.service" ];
};

#reverse proxy config
  services.nginx = {
    #boilerplate stuff
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    #hardened security settings
    # Only allow PFS-enabled ciphers with AES256
    sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";
    #enable HSTS and other hardening (see nixos wiki)
    appendHttpConfig = ''
      map $scheme $hsts_header {
          https   "max-age=31536000; includeSubdomains; preload";
      }
      more_set_headers 'Strict-Transport-Security: $hsts_header';
      more_set_headers 'Referrer-Policy: strict-origin-when-cross-origin';
      more_set_headers 'X-Frame-Options: SAMEORIGIN';
      more_set_headers 'X-Content-Type-Options: nosniff';
      proxy_cookie_path / "/; secure; HttpOnly; SameSite=strict";
    '';

    #setup nextcloud proxy host
    virtualHosts."test.partanengroup.de" = {
      enableACME = lib.mkIf edge true;
      sslCertificate = lib.mkIf (!edge) "/var/lib/sslCerts/test.partanengroup.de/fullchain.pem";
      sslCertificateKey = lib.mkIf (!edge) "/var/lib/sslCerts/test.partanengroup.de/key.pem";
      sslTrustedCertificate = lib.mkIf (!edge) "/var/lib/sslCerts/test.partanengroup.de/chain.pem";
      forceSSL = true;
      http2 = true;
      locations."/" = {
        proxyPass = "http://" + subnet + "150:80";
        proxyWebsockets = true;
      };
      locations."/.well-known/carddav" = {
        proxyPass = "http://" + subnet + "150:80/remote.php/dav";
        proxyWebsockets = true;
      };
      locations."/.well-known/caldav" = {
        proxyPass = "http://" + subnet + "150:80/remote.php/dav";
        proxyWebsockets = true;
      };
    };
    #www redirect
    virtualHosts."www.test.partanengroup.de" = {
      enableACME = lib.mkIf edge true;
      sslCertificate = lib.mkIf (!edge) "/var/lib/sslCerts/www.test.partanengroup.de/fullchain.pem";
      sslCertificateKey = lib.mkIf (!edge) "/var/lib/sslCerts/www.test.partanengroup.de/key.pem";
      sslTrustedCertificate = lib.mkIf (!edge) "/var/lib/sslCerts/www.test.partanengroup.de/chain.pem";
      forceSSL = true;
      http2 = true;
      globalRedirect = "test.partanengroup.de";
    };

    #setup jellyfin proxy host
    virtualHosts."media.partanengroup.de" = {
      enableACME = lib.mkIf edge true;
      sslCertificate = lib.mkIf (!edge) "/var/lib/sslCerts/media.partanengroup.de/fullchain.pem";
      sslCertificateKey = lib.mkIf (!edge) "/var/lib/sslCerts/media.partanengroup.de/key.pem";
      sslTrustedCertificate = lib.mkIf (!edge) "/var/lib/sslCerts/media.partanengroup.de/chain.pem";
      forceSSL = true;
      http2 = true;
      locations."/" = {
        proxyPass = "http://" + subnet + "132:8096";
        proxyWebsockets = true;
      };
    };
    #www redirect
    virtualHosts."www.media.partanengroup.de" = {
      enableACME = lib.mkIf edge true;
      sslCertificate = lib.mkIf (!edge) "/var/lib/sslCerts/www.media.partanengroup.de/fullchain.pem";
      sslCertificateKey = lib.mkIf (!edge) "/var/lib/sslCerts/www.media.partanengroup.de/key.pem";
      sslTrustedCertificate = lib.mkIf (!edge) "/var/lib/sslCerts/www.media.partanengroup.de/chain.pem";
      forceSSL = true;
      http2 = true;
      globalRedirect = "media.partanengroup.de";
    };
    virtualHosts."request.media.partanengroup.de" = {
      enableACME = lib.mkIf edge true;
      sslCertificate = lib.mkIf (!edge) "/var/lib/sslCerts/request.media.partanengroup.de/fullchain.pem";
      sslCertificateKey = lib.mkIf (!edge) "/var/lib/sslCerts/request.media.partanengroup.de/key.pem";
      sslTrustedCertificate = lib.mkIf (!edge) "/var/lib/sslCerts/request.media.partanengroup.de/chain.pem";
      forceSSL = true;
      http2 = true;
      locations."/" = {
        proxyPass = "http://" + subnet + "132:5055";
        proxyWebsockets = true;
      };
    };
    #www redirect
    virtualHosts."www.request.media.partanengroup.de" = {
      enableACME = lib.mkIf edge true;
      sslCertificate = lib.mkIf (!edge) "/var/lib/sslCerts/www.request.media.partanengroup.de/fullchain.pem";
      sslCertificateKey = lib.mkIf (!edge) "/var/lib/sslCerts/www.request.media.partanengroup.de/key.pem";
      sslTrustedCertificate = lib.mkIf (!edge) "/var/lib/sslCerts/www.request.media.partanengroup.de/chain.pem";
      forceSSL = true;
      http2 = true;
      globalRedirect = "request.media.partanengroup.de";
    };

    #setup atm proxy config (restart minecraft server, using nebula unsafe_routes)
    virtualHosts."atm.partanengroup.de" = {
      enableACME = lib.mkIf edge true;
      sslCertificate = lib.mkIf (!edge) "/var/lib/sslCerts/atm.partanengroup.de/fullchain.pem";
      sslCertificateKey = lib.mkIf (!edge) "/var/lib/sslCerts/atm.partanengroup.de/key.pem";
      sslTrustedCertificate = lib.mkIf (!edge) "/var/lib/sslCerts/atm.partanengroup.de/chain.pem";
      forceSSL = true;
      http2 = true;
      locations."/" = {
        proxyPass = "http://192.168.3.107:80";
        proxyWebsockets = true;
      };
    };
    #www redirect
    virtualHosts."www.atm.partanengroup.de" = {
      enableACME = lib.mkIf edge true;
      sslCertificate = lib.mkIf (!edge) "/var/lib/sslCerts/www.atm.partanengroup.de/fullchain.pem";
      sslCertificateKey = lib.mkIf (!edge) "/var/lib/sslCerts/www.atm.partanengroup.de/key.pem";
      sslTrustedCertificate = lib.mkIf (!edge) "/var/lib/sslCerts/www.atm.partanengroup.de/chain.pem";
      forceSSL = true;
      http2 = true;
      globalRedirect = "atm.partanengroup.de";
    };

    #setup atm proxy config (restart minecraft server, using nebula unsafe_routes)
    virtualHosts."project-w.partanengroup.de" = {
      enableACME = lib.mkIf edge true;
      sslCertificate = lib.mkIf (!edge) "/var/lib/sslCerts/project-w.partanengroup.de/fullchain.pem";
      sslCertificateKey = lib.mkIf (!edge) "/var/lib/sslCerts/project-w.partanengroup.de/key.pem";
      sslTrustedCertificate = lib.mkIf (!edge) "/var/lib/sslCerts/project-w.partanengroup.de/chain.pem";
      forceSSL = true;
      http2 = true;
      locations."/" = {
        proxyPass = "http://192.168.3.136:80";
        proxyWebsockets = true;
      };
    };
    #www redirect
    virtualHosts."www.project-w.partanengroup.de" = {
      enableACME = lib.mkIf edge true;
      sslCertificate = lib.mkIf (!edge) "/var/lib/sslCerts/www.project-w.partanengroup.de/fullchain.pem";
      sslCertificateKey = lib.mkIf (!edge) "/var/lib/sslCerts/www.project-w.partanengroup.de/key.pem";
      sslTrustedCertificate = lib.mkIf (!edge) "/var/lib/sslCerts/www.project-w.partanengroup.de/chain.pem";
      forceSSL = true;
      http2 = true;
      globalRedirect = "project-w.partanengroup.de";
    };
  };

  #setup firewall
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
