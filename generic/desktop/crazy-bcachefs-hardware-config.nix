args@{
  config,
  lib,
  pkgs,
  utils,
  modulesPath,
  hostName,
  ...
}:

let
  bcachefsLabel = if hostName == "JuliansPC" then "JuliansNixOSPC" else "JuliansNixOS";
  uefiLabel = if hostName == "JuliansPC" then "UEFIPC" else "UEFI";
  encryptedSwapLabel =
    if hostName == "JuliansPC" then "JuliansEncryptedSwapPC" else "JuliansEncryptedSwap";
  unlockedSwapLabel = if hostName == "JuliansPC" then "JuliansSwapPC" else "JuliansSwap";
  encryptedKeyPartitionLabel =
    if hostName == "JuliansPC" then "EncryptedKeyPartitionPC" else "EncryptedKeyPartition";
  unlockedKeyPartitionLabel = if hostName == "JuliansPC" then "KeyPartitionPC" else "KeyPartition";
  oldSystemdInitrd =
    ((import (modulesPath + "/system/boot/systemd/initrd.nix")) args)
    .config.content.boot.initrd.systemd;
  oldSystemdTmpfiles =
    ((import (modulesPath + "/system/boot/systemd/tmpfiles.nix")) args).config.boot.initrd.systemd;

  #to be able to boot without yubikey or when the tpm values temporarily don't fit anymore add a tang server in the local network as a fallback
  #requires networking, so currently not enabled for JuliansFramework
  withTangFallback = if hostName == "JuliansPC" then true else false; # make sure you added networking to initrd first!

  #JuliansPC also uses a tang server as an alternative for fido2, so change display message
  promptText =
    if hostName == "JuliansPC" then
      "Trying to unlock ${encryptedKeyPartitionLabel} using clevis (two of tpm2, fido2 and tang server). If you want to enter the encryption password instead then press Ctrl+C"
    else
      "Trying to unlock ${encryptedKeyPartitionLabel} using clevis (tpm2 + fido2). If you want to enter the encryption password instead then press Ctrl+C";
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  assertions = [
    {
      assertion = !config.system.etc.overlay.enable;
      message = "Custom assertion: Because of custom initrd script and switchting into /sysroot/root instead of /sysroot the etc overlay can't work currently. Modify it to make it work first, then remove this warning";
    }
  ];

  #KeyPartition is ext4 partition and is not part of fstab below since it's only needed in initrd
  boot.supportedFilesystems.ext4 = true;
  boot.initrd.supportedFilesystems.ext4 = true;

  #decrypt keyPartition using clevis (enable this to get many required packages into initramfs)
  #do not specify secretfile because it will be put into initramfs image, change its hash and thus change PCR 9 at next boot
  #instead we will use clevises own unlocking mechanism that puts the jwe file into luks2 header
  boot.initrd.clevis = {
    enable = true;
    useTang = withTangFallback;
  };

  #I applied an overlay for the clevis package that includes the fido2 pin for yubikey support. This copies that pin and its extra dependencies to the initrd as well
  boot.initrd.systemd = {
    extraBin =
      {
        grep = "${pkgs.gnugrep}/bin/grep";
        sed = "${pkgs.gnused}/bin/sed";
        cryptsetup = "${pkgs.cryptsetup}/bin/cryptsetup";
      }
      // lib.optionalAttrs withTangFallback {
        swapon = "${pkgs.util-linux}/bin/swapon";
      };
    storePaths = [
      (pkgs.callPackage ../packages/clevis-pin-fido2/package.nix { })
      "${pkgs.libfido2}/bin/fido2-assert"
      "${pkgs.libfido2}/bin/fido2-token"
      (lib.getLib pkgs.pcsclite)
    ];
  };

  fileSystems = {
    #temporary mount point, is source for bind mounts later
    "/" = {
      device = "/dev/disk/by-label/${bcachefsLabel}";
      fsType = "bcachefs";
      options = [ "noatime" ];
    };
    "/root/home" = {
      depends = [ "/" ];
      device = "/home";
      fsType = "none";
      neededForBoot = true;
      options = [
        "bind"
        "x-gvfs-hide" # hides mount
      ];
    };
    "/root/nix" = {
      depends = [ "/" ];
      device = "/nix";
      fsType = "none";
      neededForBoot = true;
      options = [
        "bind"
        "x-gvfs-hide" # hides mount
      ];
    };
    "/root/persist" = {
      depends = [ "/" ];
      device = "/persist";
      fsType = "none";
      neededForBoot = true;
      options = [
        "bind"
        "x-gvfs-hide" # hides mount
      ];
    };
    "/root/boot" = {
      depends = [ "/" ];
      label = uefiLabel;
      fsType = "vfat";
      neededForBoot = true;
    };
  };

  #for some reason systemd tries to load swap before decrypting it when using tang. Enable swap manually in stage 2 instead
  swapDevices = lib.lists.optional (!withTangFallback) {
    device = "/dev/disk/by-label/${unlockedSwapLabel}";
  };
  boot.initrd.luks.devices = {
    #do not add KeyPartition here because that will generate a systemd-cryptsetup service for unlocking it
    #instead I want to define my own service (see below)
    "${unlockedSwapLabel}" = {
      device = "/dev/disk/by-label/${encryptedSwapLabel}";
      keyFile = "/keyPartition/${encryptedSwapLabel}.key";
      bypassWorkqueues = true;
      allowDiscards = true;
    };
  };
  #define how long system should suspend before waking up and hibernating (hibernation always happens on low battery, whatever happens first)
  boot.resumeDevice = if withTangFallback then "" else "/dev/disk/by-label/${unlockedSwapLabel}";
  systemd.sleep.extraConfig =
    if withTangFallback then
      ""
    else
      ''
        HibernateDelaySec=1h30min
      '';

  boot.initrd.systemd = {
    enable = true;
    mounts = lib.mkForce (
      builtins.map (
        x: x // { where = builtins.replaceStrings [ "/sysroot" ] [ "/sysroot/root" ] x.where; }
      ) oldSystemdInitrd.mounts
    );
    services = {

      #bcachefs doesn't allow mounting subvolumes or rollback / (like btrfs or zfs does), so as a workaround I adjust switch-root here to execute the switch_root command on the /root subdir of the bcachefs filesystem instead
      initrd-switch-root.serviceConfig.ExecStart = lib.mkForce (
        builtins.map (
          x: builtins.replaceStrings [ "/sysroot" ] [ "/sysroot/root" ] x
        ) oldSystemdInitrd.services.initrd-switch-root.serviceConfig.ExecStart
      );
      initrd-nixos-activation = {
        script = lib.mkForce (
          builtins.replaceStrings [ "/sysroot" ] [ "/sysroot/root" ]
            oldSystemdInitrd.services.initrd-nixos-activation.script
        );
        unitConfig.RequiresMountsFor = lib.mkForce (
          builtins.map (
            x: builtins.replaceStrings [ "/sysroot" ] [ "/sysroot/root" ] x
          ) oldSystemdInitrd.services.initrd-nixos-activation.unitConfig.RequiresMountsFor
        );
      };
      systemd-tmpfiles-setup-sysroot.serviceConfig.ExecStart = lib.mkForce (
        builtins.replaceStrings [ "/sysroot" ] [ "/sysroot/root" ]
          oldSystemdTmpfiles.services.systemd-tmpfiles-setup-sysroot.serviceConfig.ExecStart
      );

      #mount keyPartition that stores encryption keys for bcachefs and swap partition
      "mount-keyPartition" = {
        description = "Temporarily mount partition that holds encryption keys";
        before = [ "systemd-cryptsetup@${unlockedSwapLabel}.service" ];
        wants = [
          "systemd-udev-settle.service"
        ] ++ lib.lists.optional withTangFallback "network-online.target";
        after = [
          "systemd-modules-load.service"
          "systemd-udev-settle.service"
        ] ++ lib.lists.optional withTangFallback "network-online.target";
        unitConfig.DefaultDependencies = false;
        serviceConfig = {
          Type = "oneshot";
          StandardOutput = "tty";
          StandardInput = "tty";
          TimeoutSec = "infinity";
          RemainAfterExit = true; # so that wants/requires statements don't restart this service
        };
        script = ''
          after_unlock() {
              echo "Unlock of keyPartition successful!"

              mkdir /keyPartition
              mount -t ext4 /dev/mapper/${unlockedKeyPartitionLabel} /keyPartition
              echo "Mounting of keyPartition successful!"
          }

          password_fallback() {
              echo "Automatic unlock not successful. TPM2 security policy might be violated, this computer might be compromised! Please enter the Passphrase if you want to proceed anyway:"
              until systemd-ask-password --id="cryptsetup:/dev/disk/by-label/${encryptedKeyPartitionLabel}" --keyname="cryptsetup" | cryptsetup open /dev/disk/by-label/${encryptedKeyPartitionLabel} ${unlockedKeyPartitionLabel}; do
                  echo "Incorrect passphrase, please try again:"
              done

              after_unlock
              exit
          }

          trap password_fallback SIGINT

          echo "${promptText}"
          if ! clevis luks unlock -d /dev/disk/by-label/${encryptedKeyPartitionLabel} -n ${unlockedKeyPartitionLabel}; then
              password_fallback
          fi
          after_unlock
        '';
      };

      #use keyfile from keyPartition to unlock automatically (overwrite script of existing NixOS service)
      "unlock-bcachefs-${utils.escapeSystemdPath "/"}" = {
        requires = [ "mount-keyPartition.service" ];
        after = [ "mount-keyPartition.service" ];
        serviceConfig.StandardOutput = "tty";
        script = lib.mkForce ''
          ${pkgs.bcachefs-tools}/bin/bcachefs unlock -f /keyPartition/${bcachefsLabel}.key /dev/disk/by-label/${bcachefsLabel}
        '';
      };

      "unmount-keyPartition" = {
        description = "Unmount temporarily mounted key partition and enable swap";
        wantedBy = [ "initrd.target" ];
        before = [ "initrd.target" ];
        requires = [ "mount-keyPartition.service" ];
        after = [
          "mount-keyPartition.service"
          "systemd-cryptsetup@${unlockedSwapLabel}.service"
          "unlock-bcachefs-${utils.escapeSystemdPath "/"}.service"
        ];
        unitConfig.DefaultDependencies = false;
        serviceConfig = {
          Type = "oneshot";
          StandardOutput = "tty";
          TimeoutSec = "infinity";
          RemainAfterExit = true;
        };
        script =
          ''
            umount /keyPartition
            cryptsetup close ${unlockedKeyPartitionLabel}
          ''
          + lib.strings.optionalString withTangFallback "swapon /dev/mapper/${unlockedSwapLabel}";
      };

      /*
        -- impermanence setup --
        differences to setup in ../disk-config-btrfs-impermanence.nix:
        - bcachefs instead of btrfs!
        - More old copies with timestaps
        - home partition doesn't get erased
        - is done with systemd instead of initrd.postDeviceCommands because of full disk encryption
      */
      "impermanence-wipe" = {
        description = "Copy current root partition away and create new one";
        wantedBy = [ "initrd.target" ];
        before = [ "sysroot.mount" ];
        requires = [ "unlock-bcachefs-${utils.escapeSystemdPath "/"}.service" ];
        after = [
          "unlock-bcachefs-${utils.escapeSystemdPath "/"}.service"
          "systemd-hibernate-resume.service"
        ];
        unitConfig.DefaultDependencies = false;
        serviceConfig = {
          Type = "oneshot";
          KeyringMode = "inherit"; # mount needs access to kernel keyring because bcachefs encryption key is stored there (unlock-bcachefs--.service unlocks partition and puts key into keyring)
          StandardOutput = "tty";
          TimeoutSec = "infinity";
          RemainAfterExit = true;
        };
        script = ''
          mkdir /bcachefs_tmp
          if mount -t bcachefs -o noatime /dev/disk/by-label/${bcachefsLabel} /bcachefs_tmp; then
              echo "Initial mount of bcachefs root successful"
          else
              echo "Initial mount of bcachefs root failed, trying fsck,fix_errors now. This may take some time, please wait..."
              mount -t bcachefs -o noatime,fsck,fix_errors /dev/disk/by-label/${bcachefsLabel} /bcachefs_tmp
          fi

          if [[ -e /bcachefs_tmp/root ]]; then
              mkdir -p /bcachefs_tmp/old_roots
              timestamp=$(date --date="@$(stat -c %Y /bcachefs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
              bcachefs subvolume snapshot -r /bcachefs_tmp/root "/bcachefs_tmp/old_roots/$timestamp"
              bcachefs subvolume delete /bcachefs_tmp/root
              echo "Successfully snapshoted and removed root subvolume"
          fi

          for i in $(find /bcachefs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
              bcachefs subvolume delete "$i"
              echo "Successfully garbage collected old snapshot $i"
          done

          bcachefs subvolume create /bcachefs_tmp/root
          echo "Successfully create new root subvolume"
          umount /bcachefs_tmp
        '';
      };
    };
  };

  #also change some environment stuff
  environment = {
    variables.ESP_PATH = "/boot"; # since with my setup the mount point in fstab is set to /root/boot this variable ensures that sbctl still finds efi partition
    systemPackages = [ pkgs.clevis ]; # to update bindings
  };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  # networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp0s13f0u1u3.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp166s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
