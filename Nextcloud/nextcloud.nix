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
    config.adminpassFile = ./adminpassFile.txt;

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
      mail_sendmailnode = "smtp";
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
      inherit news contacts calendar tasks talk bookmarks polls keeweb;
    };
    extraAppsEnable = true;
  };

  #update password in this file before nixos-rebuild switch
  environment.etc."nextcloud-secrets.json".source = ./nextcloud-secrets.json;

  #set firewall rule
  networking.firewall.allowedTCPPorts = [ 80 ];
}
