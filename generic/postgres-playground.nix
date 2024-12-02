{ config, lib, pkgs, ... }:

{
  sops.secrets."pgadmin".sopsFile = ../secrets/postgres.yaml;

  #impermanence stuff for postgres
  systemd.tmpfiles.settings."10-postgresql"."/persist/postgresql/${config.services.postgresql.package.psqlSchema}"."d" = {
    user = "postgres";
    group = "postgres";
    mode = "0700";
  };
  environment.persistence."/persist".directories = [{
    directory = "/var/lib/private/pgadmin";
    user = "pgadmin";
    group = "pgadmin";
    mode = "0700";
  }];

  services =  {
    pgadmin = {
      enable = true;
      initialEmail = "user@example.com";
      initialPasswordFile = config.sops.secrets."pgadmin".path;
    };
    postgresql = {
      enable = true;
      dataDir = "/persist/postgresql/${config.services.postgresql.package.psqlSchema}";
      ensureDatabases = [ "postgres" ];
      ensureUsers = [{
        name = "postgres";
        ensureDBOwnership = true;
        ensureClauses.login = true;
        ensureClauses.createdb = true;
      }];
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
  };
}
