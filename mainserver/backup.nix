{ config, hostName, ... }:

{
  sops.secrets."restic/backupServer".sopsFile = ../secrets/${hostName}/restic.yaml;

  services.restic.backups."newData" = {
    repository = "rest:http://192.168.3.30:8000/mainserver/newData";
    environmentFile = config.sops.secrets."restic/backupServer".path;
    passwordFile = config.sops.secrets."restic/backupServer".path;
    initialize = true;
    runCheck = true;
    paths = [
      "/newData"
    ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      #RandomizedDelaySec = "1h";
    };
  };
}
