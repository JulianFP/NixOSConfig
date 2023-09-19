{config, lib, pkgs, ... }:

{
#setup acme for let's encrypt validation
security.acme = {
  acceptTerms = true;
  defaults.email = "admin@partanengroup.de";
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
      enableACME = true;
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
  };
}
