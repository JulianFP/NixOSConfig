{
  config,
  lib,
  pkgs,
  hostName,
  ...
}:

let
  cfg = config.services.nextcloud;
in
{
  networking.hosts = {
    #to access Kanidm using it's domain over local container ip
    "10.42.42.137" = [ "account.partanengroup.de" ];
  };

  #setup sops secrets for nextcloud
  sops.secrets."nextcloud/adminPass" = {
    mode = "0440";
    owner = "nextcloud";
    sopsFile = ../../secrets/${hostName}/nextcloud.yaml;
  };
  sops.secrets."nextcloud/secrets.json" = {
    mode = "0440";
    owner = "nextcloud";
    sopsFile = ../../secrets/${hostName}/nextcloud.yaml;
  };

  #nextcloud setup
  services.nextcloud = {
    #boilerplate stuff
    enable = true;
    home = "/persist/backMeUp/nextcloud";
    datadir = "/mnt/cloudData/nextcloud";
    hostName = if hostName == "Nextcloud" then "partanengroup.de" else "test.partanengroup.de";
    package = pkgs.nextcloud30;
    secretFile = config.sops.secrets."nextcloud/secrets.json".path;
    config.adminuser = "admin";
    config.adminpassFile = config.sops.secrets."nextcloud/adminPass".path;

    #setup database
    database.createLocally = true;
    config.dbtype = "mysql";

    #setup caching
    caching.redis = true;
    configureRedis = true;

    #setup php
    maxUploadSize = "32G";
    phpOptions = {
      max_file_uploads = "20";
      "opcache.enable" = "1";
      "opcache.interned_strings_buffer" = "16";
      "opcache.max_accelerated_files" = "10000";
      "opcache.memory_consumption" = "2048";
      "opcache.save_comments" = "1";
      "opcache.validate_timestamps" = "0"; # disables opcache.revalidate_freq completely
      "opcache.jit" = "1255"; # php 8.0 or above required
      "opcache.jit_buffer_size" = "128M"; # php 8.0 or above required
    };
    poolSettings = {
      pm = "dynamic";
      "pm.max_children" = "128";
      "pm.start_servers" = "12";
      "pm.max_requests" = "512";
      "pm.min_spare_servers" = "12";
      "pm.max_spare_servers" = "32";
    };

    settings =
      let
        oidc_client_id = if hostName == "Nextcloud" then "nextcloud_service" else "test-nextcloud_service";
      in
      {
        #setup reverse proxy config
        trusted_proxies = [
          "10.42.42.1"
          "48.42.0.5"
        ];
        overwriteprotocol = "https";
        overwritehost = cfg.hostName;
        overwrite.cli.url = "${cfg.settings.overwriteprotocol}://${cfg.settings.overwritehost}";

        #set timeframe in which heavy operations should be done. This value as in hour of the day (1 -> 01:00) + 4 hour time window
        maintenance_window_start = 1;

        #some generic stuff
        default_phone_region = "DE";
        filelocking.enabled = true;

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

        #log as file for better compatibility with Nextcloud logreader and promtail
        log_type = "file";

        #OIDC related
        allow_user_to_change_display_name = false;
        lost_password_link = "disabled";
        oidc_login_client_id = oidc_client_id;
        oidc_login_provider_url = "https://account.partanengroup.de/oauth2/openid/${oidc_client_id}";
        oidc_login_auto_redirect = false;
        oidc_login_default_quota = "1000000000";
        oidc_login_button_text = "Login with PartanenGroup Account";
        oidc_login_hide_password_form = true;
        oidc_login_attributes = {
          "id" = "sub";
          "name" = "name";
          "mail" = "email";
          "quota" = "nextcloud_quota";
          "groups" = "nextcloud_groups";
        };
        oidc_login_scope = "openid profile email";
        oidc_login_disable_registration = false;
        oidc_create_groups = true;
        oidc_login_webdav_enabled = true;
        oidc_login_password_authentication = true; # for WebDav clients like DAVx5
        oidc_login_code_challenge_method = "S256";
      };

    #install nextcloud apps
    extraApps = {
      inherit (cfg.package.packages.apps)
        oidc_login
        bookmarks
        calendar
        contacts
        groupfolders
        notes
        polls
        registration
        spreed
        tasks
        twofactor_webauthn
        ;
    };
    extraAppsEnable = true;
  };

  services.mysqlBackup = {
    enable = true;
    databases = [ "nextcloud" ];
    singleTransaction = true;
    calendar = "02:00:00";
    compressionAlg = "zstd";
    location = "/persist/backMeUp/mysqlBackup";
  };

  #scrape Nextcloud logs with promtail
  services.promtail.configuration.scrape_configs = [
    {
      job_name = "nextcloud";
      static_configs = [
        {
          targets = [ "localhost" ];
          labels = {
            job = "nextcloud";
            host = hostName;
            __path__ = "${config.services.nextcloud.datadir}/data/nextcloud.log";
          };
        }
      ];
    }
  ];
  users.users.promtail.extraGroups = lib.mkIf config.services.promtail.enable [ "nextcloud" ];
}
