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
  systemd.services."create-backup-dirs" = {
    path = [
      pkgs.zfs
      pkgs.btrfs-progs
      pkgs.util-linux
    ];
    restartIfChanged = false;
    serviceConfig.Type = "oneshot";
    script = ''
      echo "Creating zfs and btrfs snapshots..."
      mkdir /zfs-backup-snapshot
      zfs snapshot newData@backup-snapshot
      mount -t zfs newData@backup-snapshot /zfs-backup-snapshot
      btrfs subvolume snapshot /persist/backMeUp btrfs-backup-snapshot
      echo "Successfully created zfs and btrfs snapshots"
    '';
  };
  systemd.services."remove-backup-dirs" = {
    path = [
      pkgs.zfs
      pkgs.btrfs-progs
      pkgs.util-linux
    ];
    restartIfChanged = false;
    serviceConfig.Type = "oneshot";
    script = ''
      echo "Destroying zfs and btrfs snapshots..."
      umount /zfs-backup-snapshot
      rm /zfs-backup-snapshot -r
      zfs destroy newData@backup-snapshot
      btrfs subvolume delete btrfs-backup-snapshot
      echo "Successfully destroyed zfs and btrfs snapshots"
    '';
  };
  services.restic.backups."backupServer" = {
    repository = "rest:http://192.168.3.30:8000/julian/mainserver";
    environmentFile = config.sops.secrets."restic/backupServer".path;
    passwordFile = config.sops.secrets."restic/backupServerRepository".path;
    initialize = true;
    runCheck = true;
    progressFps = 0.1;
    paths = [
      "/zfs-backup-snapshot"
      "/btrfs-backup-snapshot"
    ];
    timerConfig = {
      OnCalendar = "03:00";
      Persistent = true;
    };
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 12"
      "--keep-yearly 3"
    ];
  };
  systemd.services."restic-backups-backupServer" = {
    wants = [
      "create-backup-dirs.service"
      "remove-backup-dirs.service"
    ];
    after = [
      "create-backup-dirs.service"
    ];
    before = [
      "remove-backup-dirs.service"
    ];
  };

  systemd.services."create-offsite-backup-dirs" = {
    path = [
      pkgs.zfs
      pkgs.btrfs-progs
      pkgs.util-linux
    ];
    restartIfChanged = false;
    serviceConfig.Type = "oneshot";
    script = ''
      echo "Creating zfs and btrfs snapshots..."
      mkdir /zfs-offsite-backup-snapshot
      zfs snapshot newData@offsite-backup-snapshot
      mount -t zfs newData@offsite-backup-snapshot /zfs-offsite-backup-snapshot
      btrfs subvolume snapshot /persist/backMeUp btrfs-offsite-backup-snapshot
      echo "Successfully created zfs and btrfs snapshots"
    '';
  };
  systemd.services."remove-offsite-backup-dirs" = {
    path = [
      pkgs.zfs
      pkgs.btrfs-progs
      pkgs.util-linux
    ];
    restartIfChanged = false;
    serviceConfig.Type = "oneshot";
    script = ''
      echo "Destroying zfs and btrfs snapshots..."
      umount /zfs-offsite-backup-snapshot
      rm /zfs-offsite-backup-snapshot -r
      zfs destroy newData@offsite-backup-snapshot
      btrfs subvolume delete btrfs-offsite-backup-snapshot
      echo "Successfully destroyed zfs and btrfs snapshots"
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
      "/zfs-offsite-backup-snapshot"
      "/btrfs-offsite-backup-snapshot"
    ];
    timerConfig = {
      OnCalendar = "05:00";
      Persistent = true;
    };
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 12"
      "--keep-yearly 3"
    ];
  };
  systemd.services."restic-backups-backupServerOffsite" = {
    wants = [
      "create-offsite-backup-dirs.service"
      "remove-offsite-backup-dirs.service"
    ];
    after = [
      "create-offsite-backup-dirs.service"
    ];
    before = [
      "remove-offsite-backup-dirs.service"
    ];
  };
}
