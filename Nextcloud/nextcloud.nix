{ config, lib, pkgs, ... }:

{
  services.nextcloud = {
    #boilerplate stuff
    enable = true;
    hostName = "test.partanengroup.de";
    package = pkgs.nextcloud27;
    secretFile = "/etc/nextcloud-secrets.json";
    config.defaultPhoneRegion = "DE";
    config.adminuser = "admin";
    config.adminpassFile = "/etc/nixos/Nextcloud/adminpassFile.txt";

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
        "192.168.3.100"
      ];
      overwriteProtocol = "https";
    };
    extraOptions = {
      overwritehost = "test.partanengroup.de";
      overwritecondaddr = "^192\\.168\\.3\\.100$";
      "overwrite.cli.url" = "https://partanengroup.de";
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

  #update password in this file before nixos-rebuild switch
  environment.etc."nextcloud-secrets.json".source = ./nextcloud-secrets.json;

  #set firewall rule
  networking.firewall.allowedTCPPorts = [ 80 ];
}
