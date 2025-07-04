{ config, hostName, ... }:

{
  sops.secrets = {
    "restic/backupServer".sopsFile = ../secrets/${hostName}/restic.yaml;
    "restic/repositoryPassword".sopsFile = ../secrets/${hostName}/restic.yaml;
  };

  services.restic.backups."mainserver" = {
    repository = "rest:http://192.168.3.30:8000/julian/mainserver";
    environmentFile = config.sops.secrets."restic/backupServer".path;
    passwordFile = config.sops.secrets."restic/repositoryPassword".path;
    initialize = true;
    runCheck = true;
    progressFps = 0.1;
    paths = [
      "/newData"
      "/persist/backMeUp"
    ];
    timerConfig = {
      OnCalendar = "03:00";
      Persistent = true;
    };
  };
}
