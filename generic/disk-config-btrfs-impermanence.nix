# Example to create a bios compatible gpt partition
{ lib, config, inputs, ... }: 

let
  bootDev = "f6988248-1a64-4ee5-90a1-943158b8ee7d";
  bootDevPath = "/dev/disk/by-uuid/${bootDev}"; #do not change because of below!
  cfg = config.myModules.disko-btrfs-impermanence;
in 
{
  imports = [
    inputs.disko.nixosModules.disko
  ];

  options.myModules.disko-btrfs-impermanence = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    uefiOnlySystem = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    disko.devices.disk."${bootDevPath}" = if cfg.uefiOnlySystem then {
      device = bootDevPath;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            type = "EF00";
            size = "500M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          nixos = {
            name = "nixos";
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ]; # Override existing partition
              # Subvolumes must set a mountpoint in order to be mounted,
              # unless their parent is mounted
              subvolumes = {
                #volatile subvolumes (will be wiped at every reboot)
                "/root".mountpoint = "/";
                "/home".mountpoint = "/home";
                # Subvolume for the swapfile
                "/swap" = {
                  mountpoint = "/.swapvol";
                  swap.swapfile.size = "16G";
                };
                #stable subvolumes (will persist accross reboots)
                "/nix" = {
                  mountOptions = [ "noatime" ];
                  mountpoint = "/nix";
                };
                "/persist".mountpoint = "/persist";
                #The following contains everything that should also be backed up. Logs etc. would not be put in here, but just in /persist
                "/persist/backMeUp" = {}; #will be mounted under /persist/noBackup automatically because parents mountpoint is set
              };
            };
          };
        };
      };
    }
    else {
      device = bootDevPath;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            name = "boot";
            size = "1M";
            type = "EF02"; #for grub MBR
          };
          ESP = {
            name = "ESP";
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          nixos = {
            name = "nixos";
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ]; # Override existing partition
              # Subvolumes must set a mountpoint in order to be mounted,
              # unless their parent is mounted
              subvolumes = {
                #volatile subvolumes (will be wiped at every reboot)
                "/root".mountpoint = "/";
                "/home".mountpoint = "/home";
                # Subvolume for the swapfile
                "/swap" = {
                  mountpoint = "/.swapvol";
                  swap.swapfile.size = "4G";
                };
                #stable subvolumes (will persist accross reboots)
                "/nix" = {
                  mountOptions = [ "noatime" ];
                  mountpoint = "/nix";
                };
                "/persist".mountpoint = "/persist";
                #The following contains everything that should also be backed up. Logs etc. would not be put in here, but just in /persist
                "/persist/backMeUp" = {}; #will be mounted under /persist/noBackup automatically because parents mountpoint is set
              };
            };
          };
        };
      };
    };

    fileSystems."/persist".neededForBoot = true;

    #this is inspired by script used by nix-community/impermanence, but I don't need to keep that many old roots.
    #Since I keep everything I want to keep in /persist or /persist-noBackup anyway (this is a server!), there shouldn't be a reason to keep old roots around at all. I will still keep the last root to be safe.
    boot.initrd.postDeviceCommands = lib.mkAfter ''
      mkdir /btrfs_tmp
      mount /dev/disk/by-partlabel/disk-_dev_${bootDev}-nixos /btrfs_tmp

      delete_subvolume_recursively() {
          IFS=$'\n'
          for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
              delete_subvolume_recursively "/btrfs_tmp/$i"
          done
          btrfs subvolume delete "$1"
      }

      cycle_subvolume() {
          if [[ -e "/btrfs_tmp/$1" ]]; then
              if [[ -e "/btrfs_tmp/old_$1" ]]; then
                  delete_subvolume_recursively "/btrfs_tmp/old_$1"
              fi
              mv "/btrfs_tmp/$1" "/btrfs_tmp/old_$1"
          fi
          btrfs subvolume create "/btrfs_tmp/$1"
      }

      cycle_subvolume root
      cycle_subvolume home

      umount /btrfs_tmp
    '';
  };
}
