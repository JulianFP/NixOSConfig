{ ... }:

{
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
}
