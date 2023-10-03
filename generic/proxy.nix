{ lib, edge, ... }:

# This is the setup for all my (reverse) proxies. Currently I have one in the cloud that is exposed to the internet (IonosVPS) and one locally that is not (LocalProxy)
# for the first one edge is set, for the second not. The first one syncs ssl certs to the second one
{
#setup acme for let's encrypt validation if this is on edge
security.acme = lib.mkIf edge {
  acceptTerms = true;
  defaults.email = "admin@partanengroup.de";
  #ssh matchBlock for LocalProxy has to be setup on edge server
  defaults.postRun = ''
    scp -r . LocalProxy:/var/lib/acme/
    ssh root@48.42.1.130 "chown -R acme:nginx /var/lib/acme/*"
  '';
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
      add_header Strict-Transport-Security $hsts_header;
      add_header 'Referrer-Policy' 'origin-when-cross-origin';
      add_header X-Frame-Options DENY;
      add_header X-Content-Type-Options nosniff;
      proxy_cookie_path / "/; secure; HttpOnly; SameSite=strict";
    '';

    #setup nextcloud proxy host
    virtualHosts."test.partanengroup.de" = {
      enableACME = lib.mkIf edge true;
      sslCertificate = lib.mkIf (!edge) "/var/lib/acme/test.partanengroup.de/fullchain.pem";
      sslCertificateKey = lib.mkIf (!edge) "/var/lib/acme/test.partanengroup.de/key.pem";
      sslTrustedCertificate = lib.mkIf (!edge) "/var/lib/acme/test.partanengroup.de/chain.pem";
      forceSSL = true;
      http2 = true;
      locations."/" = {
        proxyPass = "http://48.42.1.150:80";
        proxyWebsockets = true;
      };
      locations."/.well-known/carddav" = {
        proxyPass = "http://48.42.1.150:80/remote.php/dav";
        proxyWebsockets = true;
      };
      locations."/.well-known/caldav" = {
        proxyPass = "http://48.42.1.150:80/remote.php/dav";
        proxyWebsockets = true;
      };
    };
    #www redirect
    virtualHosts."www.test.partanengroup.de" = {
      enableACME = lib.mkIf edge true;
      sslCertificate = lib.mkIf (!edge) "/var/lib/acme/www.test.partanengroup.de/fullchain.pem";
      sslCertificateKey = lib.mkIf (!edge) "/var/lib/acme/www.test.partanengroup.de/key.pem";
      sslTrustedCertificate = lib.mkIf (!edge) "/var/lib/acme/www.test.partanengroup.de/chain.pem";
      forceSSL = true;
      http2 = true;
      globalRedirect = "test.partanengroup.de";
    };
  };

  #setup firewall
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
