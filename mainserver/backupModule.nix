{
  config,
  pkgs,
  lib,
  ...
}:

let
  enabledBackups = lib.filterAttrs (n: v: v.enable) config.myModules.mainserverResticBackups;
in
{
  options.myModules.mainserverResticBackups = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable or disable this backup config";
          };
          repository = lib.mkOption {
            type = lib.types.singleLineStr;
            description = "repository to backup to.";
          };
          environmentFile = lib.mkOption {
            type = lib.types.singleLineStr;
            description = "file containing the credentials to access the repository, in the format of an EnvironmentFile as described by systemd.exec(5)";
          };
          passwordFile = lib.mkOption {
            type = lib.types.singleLineStr;
            description = "Read the repository password from a file.";
          };
          timerConfig = lib.mkOption {
            type = lib.types.nullOr lib.types.attrs;
            description = "When to run the backup. See systemd.timer(5) for details. If null no timer is created and the backup will only run when explicitly started.";
          };
        };
      }
    );
  };

  config = {
    environment.persistence."/persist".directories = lib.mapAttrsToList (
      backupName: _: "/var/cache/restic-backups-${backupName}"
    ) enabledBackups;

    services.restic.backups = builtins.mapAttrs (backupName: backupConfig: {
      inherit (backupConfig)
        repository
        environmentFile
        passwordFile
        timerConfig
        ;
      initialize = true;
      runCheck = true;
      progressFps = 0.1;
      paths = [
        "/zfs-backup-snapshot-${backupName}"
        "/btrfs-backup-snapshot-${backupName}"
      ];
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 12"
        "--keep-yearly 3"
      ];
    }) enabledBackups;

    systemd.services = lib.mkMerge (
      lib.mapAttrsToList (backupName: _: {
        "create-backup-dirs-${backupName}" = {
          path = [
            pkgs.zfs
            pkgs.btrfs-progs
            pkgs.util-linux
          ];
          restartIfChanged = false;
          serviceConfig.Type = "oneshot";
          script = ''
            echo "Creating zfs and btrfs snapshots for restic backup ${backupName}..."
            mkdir /zfs-backup-snapshot-${backupName}
            zfs snapshot -r newData/backMeUp@backup-snapshot-${backupName}
            mount -t zfs newData/backMeUp@backup-snapshot-${backupName} /zfs-backup-snapshot-${backupName}
            btrfs subvolume snapshot /persist/backMeUp btrfs-backup-snapshot-${backupName}
            echo "Successfully created zfs and btrfs snapshots for restic backup ${backupName}"
          '';
        };
        "remove-backup-dirs-${backupName}" = {
          path = [
            pkgs.zfs
            pkgs.btrfs-progs
            pkgs.util-linux
          ];
          restartIfChanged = false;
          serviceConfig.Type = "oneshot";
          script = ''
            echo "Destroying zfs and btrfs snapshots from restic backup ${backupName}..."
            umount /zfs-backup-snapshot-${backupName}
            rm /zfs-backup-snapshot-${backupName} -r
            zfs destroy -r newData/backMeUp@backup-snapshot-${backupName}
            btrfs subvolume delete btrfs-backup-snapshot-${backupName}
            echo "Successfully destroyed zfs and btrfs snapshots from restic backup ${backupName}"
          '';
        };
        "restic-backups-${backupName}" = {
          wants = [
            "create-backup-dirs-${backupName}.service"
            "remove-backup-dirs-${backupName}.service"
          ];
          after = [
            "create-backup-dirs-${backupName}.service"
          ];
          before = [
            "remove-backup-dirs-${backupName}.service"
          ];
        };
      }) enabledBackups
    );
  };
}
