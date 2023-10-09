{ config, inputs, ... }: 

{
  boot.loader.grub.device = "/dev/vda";
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
  boot.initrd.kernelModules = [ "nvme" ];
  fileSystems."/" = { device = "/dev/vda1"; fsType = "ext4"; };

  networking.domain = "";

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;

  #nebula firewall
  services.nebula.networks."serverNetwork" = {
    firewall.inbound = [
      {
        port = "22";
        proto = "tcp";
        group = "admin";
      }
    ];
    settings.tun.unsafe_routes = [{
      route = "192.168.3.0/24";
      via = "48.42.0.2";
    }];
  };

  #openssh client key config and add LocalProxy to known_hosts
  sops.secrets."openssh/IonosVPS" = {
    sopsFile = ../secrets/IonosVPS/ssh.yaml;
  };
  imports = [
    ./dnat.nix #for dnat config
    inputs.home-manager-stable.nixosModules.home-manager 
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.root = {
          programs.ssh = {
            enable = true;
            userKnownHostsFile = "~/.ssh/known_hosts ~/.ssh/known_hostsHM";
            matchBlocks = {
              "LocalProxy" = {
                hostname = "48.42.1.130";
                user = "root";
                identityFile = config.sops.secrets."openssh/IonosVPS".path;
              };
            };
          };
          home.file.".ssh/known_hostsHM" = {
            text = "48.42.1.130 " + builtins.readFile ../publicKeys/LocalProxy-host.pub;
          };

          home.stateVersion = "23.05";
          programs.home-manager.enable = true;
        };
      };
    }
  ];

}
