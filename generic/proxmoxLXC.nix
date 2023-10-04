{ modulesPath, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ./server.nix
  ];

  #disable hostname configuration through proxmox 
  proxmoxLXC.manageHostName = true;
}
