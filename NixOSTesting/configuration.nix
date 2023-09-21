{ ... }:

# gets imported by genericNixOS/nebula.nix (for this hostName only)
{
  services.nebula.networks."serverNetwork" = {
    firewall.inbound = [
      {
        port = "22";
        proto = "tcp";
        group = "admin";
      }
    ];
  };
}
