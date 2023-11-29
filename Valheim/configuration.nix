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
    ];
    allowedTCPPorts = [
      2456
      2457
    ];
  };

  services.nebula.networks."serverNetwork" = {
    firewall.inbound = [
      {
        port = "22";
        proto = "tcp";
        group = "admin";
      }
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
