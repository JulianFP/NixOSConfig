{ config, pkgs, hostName, ... }:

{
  #setup sops secrets for nextcloud 
  sops.secrets."nextcloud/adminPass" = {
    mode = "0440";
    owner = "nextcloud";
    sopsFile = ../secrets/${hostName}/nextcloud.yaml;
  };
  sops.secrets."nextcloud/secrets.json" = {
    mode = "0440";
    owner = "nextcloud";
    sopsFile = ../secrets/${hostName}/nextcloud.yaml;
  };

  #nextcloud setup
  services.nextcloud = {
    #boilerplate stuff
    enable = true;
    hostName = if hostName == "Nextcloud" then "partanengroup.de" else "test.partanengroup.de";
    package = pkgs.nextcloud27;
    secretFile = config.sops.secrets."nextcloud/secrets.json".path;
    config.defaultPhoneRegion = "DE";
    config.adminuser = "admin";
    config.adminpassFile = config.sops.secrets."nextcloud/adminPass".path;

    #setup database
    database.createLocally = true;
    config = {
      dbtype = "mysql";
      dbtableprefix = "oc_";
    };

    #setup caching
    caching.redis = true;
    configureRedis = true;
    extraOptions.filelocking.enabled = true;

    #setup php
    maxUploadSize = "32G";
    phpOptions = {
      max_file_uploads = "20";
      "opcache.enable" = "1";
      "opcache.interned_strings_buffer" = "16";
      "opcache.max_accelerated_files" = "10000";
      "opcache.memory_consumption" = "192";
      "opcache.save_comments" = "1";
      "opcache.validate_timestamps" = "0"; #disables opcache.revalidate_freq completely
      "opcache.jit" = "1255"; #php 8.0 or above required
      "opcache.jit_buffer_size" = "128M"; #php 8.0 or above required
    };
    poolSettings = {
      pm = "dynamic";
      "pm.max_children" = "128";
      "pm.start_servers" = "12";
      "pm.max_requests" = "512";
      "pm.min_spare_servers" = "12";
      "pm.max_spare_servers" = "32";
    };

    #setup reverse proxy config
    config = {
      trustedProxies = [
        "192.168.3.130"
        "48.42.0.5"
      ];
      overwriteProtocol = "https";
    };

    #mail delivery
    extraOptions = {
      mail_smtpmode = "smtp";
      mail_sendmailmode = "smtp";
      mail_from_address = "admin";
      mail_smtpauth = 1;
      mail_smtphost = "mail.partanengroup.de";
      mail_smtpport = "587";
      mail_smtpname = "admin@partanengroup.de";
      mail_smtpsecure = "tls";
      mail_domain = "partanengroup.de";
      mail_smtpauthtype = "PLAIN";
    };
    
    #install nextcloud apps
    extraApps = with config.services.nextcloud.package.packages.apps; {
      inherit bookmarks calendar contacts groupfolders keeweb news notes polls registration spreed tasks twofactor_webauthn;
    };
    extraAppsEnable = true;
  };

  #set firewall rules (for both NixOS and nebula firewalls)
  networking.firewall.allowedTCPPorts = [ 80 ];
  services.nebula.networks."serverNetwork".firewall.inbound = [
    {
      port = "22";
      proto = "tcp";
      group = "admin";
    }
    {
      port = "80";
      proto = "tcp";
      group = "edge";
    }
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
