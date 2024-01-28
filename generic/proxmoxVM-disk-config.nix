# Example to create a bios compatible gpt partition
{ lib, disks ? [ "/dev/sda" ], ... }: {
  disk = lib.genAttrs disks (dev: {
    device = dev;
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
              # Subvolume name is different from mountpoint
              "/root" = {
                mountpoint = "/";
              };
              # Subvolume name is the same as the mountpoint
              "/home" = {
                mountpoint = "/home";
              };
              "/nix" = {
                mountOptions = [ "noatime" ];
                mountpoint = "/nix";
              };
              # Subvolume for the swapfile
              "/swap" = {
                mountpoint = "/.swapvol";
                swap.swapfile.size = "4G";
              };
            };
          };
        };
      };
    };
  });
}
