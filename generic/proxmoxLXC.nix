{ modulesPath, vmID, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ./server.nix
  ];

  #disable hostname and networking configuration through proxmox 
  proxmoxLXC = {
    manageHostName = true;
    manageNetwork = true;
  };

#networking config (don't use systemd-networkd because the host will manage/overwrite this config)
  networking = {
    enableIPv6 = false;
    nameservers = [
      "192.168.3.1"
      "1.1.1.1"
    ];
    interfaces = {
      "eth0" = {
        ipv4.addresses = [{
          address = "192.168.3.${builtins.toString vmID}";
          prefixLength = 24;
        }];
        useDHCP = false;
      };
    };
    defaultGateway = {
      address = "192.168.3.1";
      interface = "eth0";
    };
  };
}
