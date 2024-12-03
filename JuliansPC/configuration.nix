{ lib, ...}:

{
  imports = [
    ./hardware-configuration.nix # Include the results of the hardware scan.
    ../generic/ssh.nix
  ];

  # Star Citizen tweaks
  boot.kernel.sysctl = {
      "vm.max_map_count" = lib.mkDefault 16777216; #also set by nix-gaming
      "fs.file-max" = 524288;
  };
}
