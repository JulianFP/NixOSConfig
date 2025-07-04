{
  config,
  pkgs,
  hostName,
  ...
}:

{
  sops.secrets = {
    "restic/backupServer".sopsFile = ../secrets/${hostName}/restic.yaml;
    "restic/repositoryPassword".sopsFile = ../secrets/${hostName}/restic.yaml;
  };

  environment.persistence."/persist".directories = [ "/var/cache/restic-backups-mainserver" ];
  services.restic.backups."mainserver" = {
    repository = "rest:http://192.168.3.30:8000/julian/mainserver";
    environmentFile = config.sops.secrets."restic/backupServer".path;
    passwordFile = config.sops.secrets."restic/repositoryPassword".path;
    initialize = true;
    runCheck = true;
    progressFps = 0.1;
    paths = [
      "/newData/.zfs/snapshot/backup-snapshot"
      "backup-snapshot"
    ];
    timerConfig = {
      OnCalendar = "03:00";
      Persistent = true;
    };
    backupPrepareCommand = ''
      ${pkgs.zfs}/bin/zfs snapshot newData@backup-snapshot
      ${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot /persist/backMeUp backup-snapshot
    '';
    backupCleanupCommand = ''
      ${pkgs.zfs}/bin/zfs destroy newData@backup-snapshot
      ${pkgs.btrfs-progs}/bin/btrfs subvolume delete backup-snapshot
    '';
  };
}
