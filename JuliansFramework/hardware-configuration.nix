args@{ config, lib, pkgs, utils, modulesPath, ... }:

let
  bcachefsLabel = "JuliansNixOS";
  uefiLabel = "UEFI";
  encryptedSwapLabel = "JuliansEncryptedSwap";
  unlockedSwapLabel = "JuliansSwap";
  oldSystemdInitrd = ((import (modulesPath + "/system/boot/systemd/initrd.nix")) args).config.content.boot.initrd.systemd.services;
in {
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "uas" "usbhid" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  boot.initrd.clevis = {
    enable = true;
    devices."/dev/disk/by-label/${bcachefsLabel}".secretFile = ./fs-decrypt-secret.jwe;
  };
  #I applied an overlay for the clevis package that includes the fido2 pin for yubikey support. This copies that pin and its extra dependencies to the initrd as well
  boot.initrd.systemd = {
    extraBin = {
      grep = "${pkgs.gnugrep}/bin/grep";
    };
    storePaths = [
      (pkgs.callPackage ../generic/packages/clevis-pin-fido2/package.nix {})
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
        "x-gvfs-hide" #hides mount
      ]; 
    };
    "/root/nix" = {
      depends = [ "/" ];
      device = "/nix";
      fsType = "none";
      neededForBoot = true;
      options = [ 
        "bind" 
        "x-gvfs-hide" #hides mount
      ]; 
    };
    "/root/persist" = {
      depends = [ "/" ];
      device = "/persist";
      fsType = "none";
      neededForBoot = true;
      options = [ 
        "bind" 
        "x-gvfs-hide" #hides mount
      ]; 
    };
    "/root/boot" = { 
      depends = [ "/" ];
      label = uefiLabel;
      fsType = "vfat";
      neededForBoot = true;
    };
  };

  swapDevices = [{
    device = "/dev/mapper/${unlockedSwapLabel}";
    encrypted = {
      enable = true;
      blkDev = "/dev/disk/by-label/${encryptedSwapLabel}";
      label = unlockedSwapLabel;
      keyFile = "/bcachefs_tmp/persist/swapPart.key";
    };
  }];
  boot.initrd.luks.devices."${unlockedSwapLabel}" = {
    bypassWorkqueues = true;
    allowDiscards = true;
  };

  #define how long system should suspend before waking up and hibernating (hibernation always happens on low battery, whatever happens first)
  boot.resumeDevice = "/dev/mapper/${unlockedSwapLabel}";
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=1h30min
  '';

  boot.initrd.systemd = {
    enable = true;
    services = {

      #bcachefs doesn't allow mounting subvolumes or rollback / (like btrfs or zfs does), so as a workaround I adjust switch-root here to execute the switch_root command on the /root subdir of the bcachefs filesystem instead
      initrd-switch-root.serviceConfig.ExecStart = lib.mkForce (builtins.map (x: builtins.replaceStrings ["/sysroot"] ["/sysroot/root"] x) oldSystemdInitrd.initrd-switch-root.serviceConfig.ExecStart);
      initrd-nixos-activation.script = lib.mkForce (builtins.replaceStrings ["/sysroot"] ["/sysroot/root"] oldSystemdInitrd.initrd-nixos-activation.script);

      #bcachefs doesn't support swap files yet, so I use a luks-encrypted swap partition instead.
      #It gets decrypted using a key file on the encrypted bcachefs filesystem, and to get hibernation the swap volume needs to be
      #decrypted before sysroot.mount because in hibernation the mounts are loaded from swap as well
      "temp-mount-bcachefs" = {
        description = "Early mount bcachefs root";
        wantedBy = [ "initrd.target" ];
        after = [ "unlock-bcachefs-${utils.escapeSystemdPath "/"}.service" ];
        before = [ "systemd-cryptsetup@${unlockedSwapLabel}.service" ];
        unitConfig.DefaultDependencies = false;
        serviceConfig = {
          Type = "oneshot";
          KeyringMode = "inherit"; #mount needs access to kernel keyring because bcachefs encryption key is stored there (unlock-bcachefs--.service unlocks partition and puts key into keyring)
        };
        script = ''
          mkdir /bcachefs_tmp
          mount /dev/disk/by-label/${bcachefsLabel} /bcachefs_tmp
        '';
      };

      #I use this dummy service to define that the cryptsetup service that unlocks the swap partition needs to run before setting up swap
      #this service on its own does nothing
      dummyServices = {
        description = "dummy service";
        wantedBy = [ "initrd.target" ];
        after = [ "systemd-cryptsetup@${unlockedSwapLabel}.service" ];
        before = [ "${utils.escapeSystemdPath config.boot.resumeDevice}.swap" ];
      };

      /*
      -- impermanence setup --
      differences to setup in ../generic/btrfs-impermanence-disk-config.nix:
      - bcachefs instead of btrfs!
      - More old copies with timestaps
      - home partition doesn't get erased
      - is done with systemd instead of initrd.postDeviceCommands because of full disk encryption
      */
      "impermanence-wipe" = {
        description = "Copy current root partition away and create new one";
        wantedBy = [ "initrd.target" ];
        after = [ "unlock-bcachefs-${utils.escapeSystemdPath "/"}.service" "temp-mount-bcachefs.service" "systemd-hibernate-resume.service" ];
        before = [ "sysroot.mount" ];
        unitConfig.DefaultDependencies = false;
        serviceConfig.Type = "oneshot";
        script = ''
          if [[ -e /bcachefs_tmp/root ]]; then
              mkdir -p /bcachefs_tmp/old_roots
              timestamp=$(date --date="@$(stat -c %Y /bcachefs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
              mv /bcachefs_tmp/root "/bcachefs_tmp/old_roots/$timestamp"
          fi

          for i in $(find /bcachefs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
              bcachefs subvolume delete "$i"
          done

          bcachefs subvolume create /bcachefs_tmp/root
          umount /bcachefs_tmp
        '';
      };
    };
  };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp0s13f0u1u3.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp166s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
