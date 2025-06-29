{
  config,
  lib,
  pkgs,
  ...
}:

{
  sops.secrets."pgadmin".sopsFile = ../../secrets/postgres.yaml;

  #impermanence stuff for postgres
  systemd.tmpfiles.settings."10-postgresql"."/persist/postgresql/${config.services.postgresql.package.psqlSchema}"."d" =
    {
      user = "postgres";
      group = "postgres";
      mode = "0700";
    };
  environment.persistence."/persist".directories = [
    {
      directory = "/var/lib/private/pgadmin";
      user = "pgadmin";
      group = "pgadmin";
      mode = "0700";
    }
    {
      directory = "/var/lib/kanidm";
      user = "kanidm";
      group = "kanidm";
      mode = "0770";
    }
  ];

  services = {
    pgadmin = {
      enable = true;
      initialEmail = "user@example.com";
      initialPasswordFile = config.sops.secrets."pgadmin".path;
    };
    postgresql = {
      enable = true;
      dataDir = "/persist/postgresql/${config.services.postgresql.package.psqlSchema}";
      ensureDatabases = [ "postgres" ];
      ensureUsers = [
        {
          name = "postgres";
          ensureDBOwnership = true;
          ensureClauses.login = true;
          ensureClauses.createdb = true;
        }
      ];
      authentication = pkgs.lib.mkOverride 10 ''
        #type database  DBuser  auth-method
        local all       all     trust
      '';
      settings = {
        log_statement = "all";
        logging_collector = true;
        log_destination = lib.mkForce "syslog";
        log_connections = true;
        log_disconnections = true;
      };
    };

    redis.servers."project-W" = {
      enable = true;
      logLevel = "debug";
      group = "users";
      port = 6379;
    };

    kanidm = {
      package = pkgs.kanidm_1_6;
      enableServer = true;
      enableClient = true;
      serverSettings = {
        domain = "localhost";
        origin = "https://localhost:8443";
        ldapbindaddress = "127.0.0.1:3636";

        #this is only fine because this is a testing/development setup that is only accessible locally
        #Never do this in production!
        #command used to generate certificate:
        #openssl req -x509 -newkey rsa:4096 -sha256 -nodes -keyout kanidm_private_key.pem -out kanidm_public_chain.pem -subj '/CN=localhost' -addext 'subjectAltName=IP:127.0.0.1' -not_after 20300101000000Z
        tls_key = ./kanidm_private_key.pem;
        tls_chain = ./kanidm_public_chain.pem;
      };
      clientSettings = {
        uri = "https://localhost:8443";
        verify_ca = false;
      };
    };
  };
}
