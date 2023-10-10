{ ... }:

{
  fileSystems."/mnt/mediadata" = {
    fsType = "ext4";
    device = "/dev/disk/by-uuid/70b6f055-dc90-4744-8bb4-10040dd0f2dd";
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  services.jellyseerr = {
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
      {
        port = "5055";
        proto = "tcp";
        group = "edge";
      }
    ];
  };
}
