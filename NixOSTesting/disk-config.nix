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
        root = {
          name = "root";
          size = "100%";
          content = {
            type = "lvm_pv";
            vg = "pool";
          };
        };
      };
    };
  });
  lvm_vg = {
    pool = {
      type = "lvm_vg";
      lvs = {
        swap = {
          size = "4G";
          content = {
            type = "swap";
            randomEncryption = true;
          };
        };
        root = {
          size = "100%FREE";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            mountOptions = [
              "defaults"
            ];
          };
        };
      };
    };
  };
}
