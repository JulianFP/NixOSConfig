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
      };

      persons = {
        "julian" = {
          displayName = "Julian";
          legalName = "Julian Partanen";
          mailAddresses = [ "julian@partanengroup.de" ];
          groups = [
            "mail-server"
          ];
        };
        "marvin" = {
          displayName = "Marvin";
          legalName = "Marvin Partanen";
          mailAddresses = [ "marvin@partanengroup.de" ];
          groups = [
            "mail-server"
          ];
        };
        "robin" = {
          displayName = "Robin";
          legalName = "Robin Partanen";
          mailAddresses = [ "robin@partanengroup.de" ];
          groups = [
            "mail-server"
          ];
        };
      };
    };
  };
}
