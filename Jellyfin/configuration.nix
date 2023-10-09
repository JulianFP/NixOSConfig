{ ... }:

{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  services.nebula.networks."serverNetwork" = {
    firewall.inbound = [
      {
        port = "22";
        proto = "tcp";
        group = "admin";
      }
      {
        port = "8096";
        proto = "tcp";
        group = "edge";
      }
    ];
  };
}
