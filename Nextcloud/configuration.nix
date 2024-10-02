{ config, pkgs, hostName, ... }:

let
  cfg = config.services.nextcloud;
in 
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
    home = "/persist/backMeUp/nextcloud";
    hostName = if hostName == "Nextcloud" then "partanengroup.de" else "test.partanengroup.de";
    package = pkgs.nextcloud29;
    secretFile = config.sops.secrets."nextcloud/secrets.json".path;
    settings.default_phone_region = "DE";
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
    settings.filelocking.enabled = true;

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

    settings = {
      #setup reverse proxy config
      trusted_proxies = [
        "192.168.3.130"
        "48.42.0.5"
      ];
      overwriteprotocol = "https";
      overwritehost = cfg.hostName;
      overwrite.cli.url = "${cfg.settings.overwriteprotocol}://${cfg.settings.overwritehost}";

      #set timeframe in which heavy operations should be done. This value as in hour of the day (1 -> 01:00) + 4 hour time window
      maintenance_window_start = 1;

      #mail delivery
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
    extraApps = {
      inherit (cfg.package.packages.apps) bookmarks calendar contacts groupfolders notes polls registration spreed tasks twofactor_webauthn;
    };
    extraAppsEnable = true;
  };

  #also change dir of mysql
  services.mysql.dataDir = "/persist/backMeUp/mysql";

  #set firewall rules (for both NixOS and nebula firewalls)
  networking.firewall.allowedTCPPorts = [ 80 ];
  services.nebula.networks."serverNetwork".firewall.inbound = [
    {
      port = "80";
      proto = "tcp";
      group = "edge";
    }
  ];
}
