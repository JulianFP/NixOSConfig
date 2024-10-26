{ ... }:

{
  fileSystems."/mnt/mediadata" = {
    fsType = "ext4";
    device = "/dev/disk/by-uuid/70b6f055-dc90-4744-8bb4-10040dd0f2dd";
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    #/var/lib/jellyfin is linked to /persist/backMeUp below. Set these paths to not be backed up
    cacheDir = "/persist/jellyfin/cache";
    logDir = "/persist/jellyfin/log";
  };

  services.jellyseerr = {
    enable = true;
    openFirewall = true;
  };
  environment.persistence."/persist/backMeUp" = {
    hideMounts = true;
    directories = [
      {directory = "/var/lib/private/jellyseerr"; user = "jellyseerr"; group = "jellyseerr";}
      {directory = "/var/lib/jellyfin"; user = "jellyfin"; group = "jellyfin";}
    ];
  };

  services.nebula.networks."serverNetwork" = {
    firewall.inbound = [
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
