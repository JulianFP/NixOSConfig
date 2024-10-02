{ ... }:

{
  imports = [
    ./valheim.nix
  ];

  #open ports for valheim and ssh
  networking.firewall = {
    allowedUDPPorts = [
      2456
      2457
      2458
    ];
    allowedTCPPorts = [
      2456
      2457
      2458
    ];
  };
}
