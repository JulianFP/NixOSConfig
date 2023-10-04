{ lib, modulesPath, vmID, ... }:

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

  #use tempfs instead of ramfs because lxc has no /boot
  sops.useTmpfs = true;

  #networking config 
  networking.useHostResolvConf = lib.mkForce false;
  systemd.network = {
    enable = true;
    networks."10-serverLAN" = {
      matchConfig.Name = "eth0@if*";
      DHCP = "no";
      address = [
        "192.168.3.${vmID}/24"
      ];
      gateway = [
        "192.168.3.1"
      ];
      dns = [
        "1.1.1.1"
      ];
    };
  };
}
