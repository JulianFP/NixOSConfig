# Example to create a bios compatible gpt partition
{ lib, inputs, ... }: 

let
  bootDev = "sda";
  bootDevPath = "/dev/${bootDev}"; #do not change because of below!
in 
{
  imports = [
    inputs.disko.nixosModules.disko
  ];

  disko.devices.disk."${bootDevPath}" = {
    device = bootDevPath;
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          name = "ESP";
          priority = 1;
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
}
