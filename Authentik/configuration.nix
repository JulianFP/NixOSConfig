{ ... }:

{
  virtualisation.docker = {
    enable = true;
    storageDriver = "btrfs";
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

  networking.firewall = {
    allowedTCPPorts = [ 9000 9443 80 443 ];
    allowedUDPPorts = [ 1812 1813 ];
  };

  services.freeradius = {
    enable = true;
  };
  users.users.radius.group = "radius";
  users.groups.radius = {};

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
