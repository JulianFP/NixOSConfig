{ lib, pkgs, edge, ... }:

# This is the setup for all my (reverse) proxies. Currently I have one in the cloud that is exposed to the internet (IonosVPS) and one locally that is not (LocalProxy)
# for the first one edge is set, for the second not. The first one syncs ssl certs to the second one
let
  subnet = if edge then "48.42.1." else "192.168.3.";
  makeProxyFor = listOfProxies: lib.attrsets.mergeAttrsList (builtins.map (x: 
  let
    baseURL = "http://" + "${x.destIP}:${builtins.toString x.destPort}";
  in {
    "${x.domain}" = {
      enableACME = lib.mkIf edge true;
      sslCertificate = lib.mkIf (!edge) "/var/lib/sslCerts/test.partanengroup.de/fullchain.pem";
      sslCertificateKey = lib.mkIf (!edge) "/var/lib/sslCerts/test.partanengroup.de/key.pem";
      sslTrustedCertificate = lib.mkIf (!edge) "/var/lib/sslCerts/test.partanengroup.de/chain.pem";
      forceSSL = true;
      http2 = true;
      locations = {
        "/" = {
          proxyPass = "${baseURL}";
          proxyWebsockets = true;
        };
      } // lib.optionalAttrs (builtins.hasAttr "locations" x) (lib.attrsets.mergeAttrsList (builtins.map (y: {
        "${y.sourcePath}" = {
          proxyPass = "${baseURL}${y.destPath}";
          proxyWebsockets = true;
        };}) x.locations));
    };
    #www redirect
    "www.${x.domain}" = {
      enableACME = lib.mkIf edge true;
      sslCertificate = lib.mkIf (!edge) "/var/lib/sslCerts/www.test.partanengroup.de/fullchain.pem";
      sslCertificateKey = lib.mkIf (!edge) "/var/lib/sslCerts/www.test.partanengroup.de/key.pem";
      sslTrustedCertificate = lib.mkIf (!edge) "/var/lib/sslCerts/www.test.partanengroup.de/chain.pem";
      forceSSL = true;
      http2 = true;
      globalRedirect = "${x.domain}";
    };
  }) listOfProxies);
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

    #allow uploads with file sizes up to 10G
    clientMaxBodySize = "10G";

    virtualHosts = makeProxyFor [
      { #nextcloud production
        domain = "partanengroup.de";
        destIP = "192.168.3.101";
        destPort = 80;
        locations = [
          {
            sourcePath = "/.well-known/carddav";
            destPath = "/remote.php/dav";
          }
          {
            sourcePath = "/.well-known/caldav";
            destPath = "/remote.php/dav";
          }
        ];
      }
      { #nextcloud test
        domain = "test.partanengroup.de";
        destIP = subnet + "150";
        destPort = 80;
        locations = [
          {
            sourcePath = "/.well-known/carddav";
            destPath = "/remote.php/dav";
          }
          {
            sourcePath = "/.well-known/caldav";
            destPath = "/remote.php/dav";
          }
        ];
      }
      { #jellyfin
        domain = "media.partanengroup.de";
        destIP = subnet + "132";
        destPort = 8096;
      }
      { #jellyseerr
        domain = "request.media.partanengroup.de";
        destIP = subnet + "132";
        destPort = 5055;
      }
      { #atm minecraft
        domain = "atm.partanengroup.de";
        destIP = "192.168.3.107";
        destPort = 80;
      }
      { #Project-W
        domain = "project-w.partanengroup.de";
        destIP = subnet + "136";
        destPort = 80;
      }
      { #Finn minecraft
        domain = "admin.finn.partanengroup.de";
        destIP = "192.168.3.115";
        destPort = 80;
      }
    ];
  };

  #setup firewall
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
