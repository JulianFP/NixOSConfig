{ ... }:

{
  fileSystems."/mnt/mediadata" = {
    fsType = "ext4";
    device = "/dev/disk/by-uuid/70b6f055-dc90-4744-8bb4-10040dd0f2dd";
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    dataDir = "/persist/backMeUp/jellyfin"; 
    #configDir is set to "${cfg.dataDir}/config" by default
    cacheDir = "/persist/jellyfin/cache";
    logDir = "/persist/jellyfin/log";
  };

  services.jellyseerr = {
    enable = true;
    openFirewall = true;
  };
  environment.persistence."/persist/backMeUp/jellyseerr" = {
    hideMounts = true;
    directories = [
      {directory = "/var/lib/private/jellyseerr"; user = "jellyseerr"; group = "jellyseerr";}
    ];
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
