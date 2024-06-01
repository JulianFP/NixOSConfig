{ config, pkgs, hostName, ... }:

{
  sops.secrets."pgadmin".sopsFile = ../secrets/${hostName}/postgres.yaml;

  services =  {
    pgadmin = {
      enable = true;
      initialEmail = "user@example.com";
      initialPasswordFile = config.sops.secrets."pgadmin".path;
    };
    postgresql = {
      enable = true;
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
    };
  };
}
