{
  config,
  pkgs,
  hostName,
  ...
}:

{
  sops.secrets."ionos".sopsFile = ../../secrets/${hostName}/kanidm.yaml;
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@partanengroup.de";
    certs."account.partanengroup.de" = {
      group = "kanidm";
      dnsProvider = "ionos";
      environmentFile = config.sops.secrets."ionos".path;
    };
  };

  sops.secrets."admin_password" = {
    sopsFile = ../../secrets/${hostName}/kanidm.yaml;
    owner = "kanidm";
  };
  sops.secrets."idm_admin_password" = {
    sopsFile = ../../secrets/${hostName}/kanidm.yaml;
    owner = "kanidm";
  };
  sops.secrets."test-nextcloud_service" = {
    sopsFile = ../../secrets/${hostName}/Nextcloud-Testing_client-secret.yaml;
    owner = "kanidm";
  };
  sops.secrets."nextcloud_service" = {
    sopsFile = ../../secrets/${hostName}/Nextcloud_client-secret.yaml;
    owner = "kanidm";
  };
  services.kanidm = {
    package = pkgs.kanidmWithSecretProvisioning;
    enableServer = true;
    serverSettings = {
      version = "2";
      domain = "account.partanengroup.de";
      origin = "https://account.partanengroup.de";
      tls_key = "/var/lib/acme/account.partanengroup.de/key.pem";
      tls_chain = "/var/lib/acme/account.partanengroup.de/fullchain.pem";
      http_client_address_info.proxy-v2 = [
        "10.42.42.1"
        "48.42.0.5"
      ];
      bindaddress = "0.0.0.0:443";
      ldapbindaddress = "10.42.42.137:3636";
    };
    provision = {
      enable = true;
      adminPasswordFile = config.sops.secrets."admin_password".path;
      idmAdminPasswordFile = config.sops.secrets."idm_admin_password".path;

      groups = {
        "mail-server" = { };
        "jellyfin" = { };
        "jellyfin-admin" = { };
        "test-nextcloud" = { };
        "nextcloud" = { };
        "family" = { };
      };

      systems.oauth2 = {
        "test-nextcloud_service" = {
          displayName = "Nextcloud test instance";
          originLanding = "https://test.partanengroup.de/apps/user_oidc/login/1";
          originUrl = "https://test.partanengroup.de/apps/user_oidc/code";
          basicSecretFile = config.sops.secrets."test-nextcloud_service".path;
          scopeMaps."test-nextcloud" = [
            "openid"
            "profile"
            "email"
          ];
          claimMaps = {
            "groups".valuesByGroup."family" = [ "Familie" ];
            "quota" = {
              valuesByGroup."family" = [ "2199023255552" ]; # 2TiB
              joinType = "ssv";
            };
          };
        };
        "nextcloud_service" = {
          displayName = "Nextcloud main instance";
          originLanding = "https://partanengroup.de/apps/user_oidc/login/1";
          originUrl = "https://partanengroup.de/apps/user_oidc/code";
          basicSecretFile = config.sops.secrets."nextcloud_service".path;
          scopeMaps."nextcloud" = [
            "openid"
            "profile"
            "email"
          ];
          claimMaps = {
            "groups".valuesByGroup."family" = [ "Familie" ];
            "quota" = {
              valuesByGroup."family" = [ "2199023255552" ]; # 2TiB
              joinType = "ssv";
            };
          };
        };
      };

      persons = {
        "julian" = {
          displayName = "Julian";
          legalName = "Julian Partanen";
          mailAddresses = [ "julian@partanengroup.de" ];
          groups = [
            "family"
            "test-nextcloud"
            "nextcloud"
            "mail-server"
            "jellyfin"
            "jellyfin-admin"
          ];
        };
        "marvin" = {
          displayName = "Marvin Partanen"; # for compatibility with old Nextcloud username until custom attributes are a thing
          legalName = "Marvin Partanen";
          mailAddresses = [ "marvin@partanengroup.de" ];
          groups = [
            "family"
            "nextcloud"
            "mail-server"
            "jellyfin"
          ];
        };
        "robin" = {
          displayName = "Robin";
          legalName = "Robin Partanen";
          mailAddresses = [ "robin@partanengroup.de" ];
          groups = [
            "family"
            "nextcloud"
            "mail-server"
            "jellyfin"
          ];
        };
        "finn" = {
          displayName = "Finn";
          legalName = "Finn Partanen";
          mailAddresses = [ "fnpartanen@t-online.de" ];
          groups = [
            "family"
            "nextcloud"
            "jellyfin"
          ];
        };
        "maria" = {
          displayName = "Maria";
          legalName = "Maria Partanen";
          mailAddresses = [ "partanen@t-online.de" ];
          groups = [
            "family"
            "nextcloud"
            "jellyfin"
          ];
        };
        "fabian" = {
          displayName = "fpartanen@t-online.de"; # for compatibility with old Nextcloud username until custom attributes are a thing
          legalName = "Fabian Partanen";
          mailAddresses = [ "fpartanen@t-online.de" ];
          groups = [
            "family"
            "nextcloud"
            "jellyfin"
          ];
        };
      };
    };
  };
}
