{ inputs, ... }:

#make sure that /persist and /persist/backMeUp exist, neededForBoot is set to true for them and they are being wiped at reboot before using this module! ./disk-config-btrfs-impermanence.nix contains a setup for this using btrfs subvolumes
{
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  #keep some basic stuff permanent
  services.openssh.hostKeys = [
    {
      bits = 4096;
      path = "/persist/ssh/ssh_host_rsa_key";
      type = "rsa";
    }
    {
      path = "/persist/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
  ];
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
    ];
    files = [
      "/etc/machine-id"
    ];
  };

}
