{ ... }:

# gets imported by genericNixOS/nebula.nix (for this hostName only)
{
  services.nebula.networks."serverNetwork" = {
    settings.tun.unsafe_routes = [{
      route = "192.168.10.0/24";
      via = "48.42.0.4";
    }];
  };
}
