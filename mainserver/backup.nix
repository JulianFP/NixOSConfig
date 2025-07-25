{
  config,
  pkgs,
  hostName,
  ...
}:

{
  sops.secrets = {
    "restic/backupServer".sopsFile = ../secrets/${hostName}/restic.yaml;
    "restic/backupServerOffsite".sopsFile = ../secrets/${hostName}/restic.yaml;
    "restic/backupServerRepository".sopsFile = ../secrets/${hostName}/restic.yaml;
    "restic/backupServerOffsiteRepository".sopsFile = ../secrets/${hostName}/restic.yaml;
  };

  environment.persistence."/persist".directories = [
    "/var/cache/restic-backups-backupServer"
    "/var/cache/restic-backups-backupServerOffsite"
  ];
  services.restic.backups."backupServer" = {
    repository = "rest:http://192.168.3.30:8000/julian/mainserver";
    environmentFile = config.sops.secrets."restic/backupServer".path;
    passwordFile = config.sops.secrets."restic/backupServerRepository".path;
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
  services.restic.backups."backupServerOffsite" = {
    repository = "rest:http://48.42.0.8:8000/julian/mainserver";
    environmentFile = config.sops.secrets."restic/backupServerOffsite".path;
    passwordFile = config.sops.secrets."restic/backupServerOffsiteRepository".path;
    initialize = true;
    runCheck = true;
    progressFps = 0.1;
    paths = [
      "/newData/.zfs/snapshot/offsite-backup-snapshot"
      "offsite-backup-snapshot"
    ];
    timerConfig = {
      OnCalendar = "05:00";
      Persistent = true;
    };
    backupPrepareCommand = ''
      ${pkgs.zfs}/bin/zfs snapshot newData@offsite-backup-snapshot
      ${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot /persist/backMeUp offsite-backup-snapshot
    '';
    backupCleanupCommand = ''
      ${pkgs.zfs}/bin/zfs destroy newData@offsite-backup-snapshot
      ${pkgs.btrfs-progs}/bin/btrfs subvolume delete offsite-backup-snapshot
    '';
  };
}
