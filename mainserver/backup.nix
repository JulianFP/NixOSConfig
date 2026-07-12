{
  config,
  hostName,
  ...
}:

{
  imports = [
    ./backupModule.nix
  ];

  sops.secrets = {
    "restic/backupServer".sopsFile = ../secrets/${hostName}/restic.yaml;
    "restic/backupServerOffsite".sopsFile = ../secrets/${hostName}/restic.yaml;
    "restic/backupServerRepository".sopsFile = ../secrets/${hostName}/restic.yaml;
    "restic/backupServerOffsiteRepository".sopsFile = ../secrets/${hostName}/restic.yaml;
  };

  myModules.mainserverResticBackups = {
    "backupServer" = {
      repository = "rest:http://192.168.3.30:8000/julian/mainserver";
      environmentFile = config.sops.secrets."restic/backupServer".path;
      passwordFile = config.sops.secrets."restic/backupServerRepository".path;
      timerConfig = {
        OnCalendar = "03:00";
        Persistent = true;
      };
    };
    "backupServerOffsite" = {
      repository = "rest:http://${
        config.myModules.nebula."serverNetwork".ipMap.backupServerOffsite
      }:8000/julian/mainserver";
      environmentFile = config.sops.secrets."restic/backupServerOffsite".path;
      passwordFile = config.sops.secrets."restic/backupServerOffsiteRepository".path;
      timerConfig = {
        OnCalendar = "05:00";
        Persistent = true;
      };
    };
  };
}
