{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

let
  pkgs-unstable = (
    import inputs.nixpkgs {
      system = "x86_64-linux";
    }
  );
in
{
  services = {
    jellyfin = {
      enable = true;
      openFirewall = true;
      #/var/lib/jellyfin is linked to /persist/backMeUp below. Set these paths to not be backed up
      cacheDir = "/persist/jellyfin/cache";
      logDir = "/persist/jellyfin/log";
    };
    jellyseerr = {
      enable = true;
      openFirewall = true;
    };
    radarr = {
      enable = true;
      dataDir = "/persist/backMeUp/radarr";
    };
    sonarr = {
      enable = true;
      dataDir = "/persist/backMeUp/sonarr";
    };
    jackett = {
      enable = true;
      package = pkgs-unstable.jackett;
      dataDir = "/persist/backMeUp/jackett";
    };
    flaresolverr.enable = true;
    transmission = {
      enable = true;
      package = pkgs.transmission_4;
      settings = {
        rpc-bind-address = "0.0.0.0";
        rpc-whitelist-enabled = false;
      };
    };
  };

  # see https://github.com/NixOS/nixpkgs/issues/258793
  systemd.services.transmission.serviceConfig = {
    RootDirectoryStartOnly = lib.mkForce null;
    RootDirectory = lib.mkForce null;
  };

  users.groups = {
    ${config.services.jellyfin.group}.members = [
      "radarr"
      "sonarr"
    ];
    ${config.services.transmission.group}.members = [
      "radarr"
      "sonarr"
    ];
  };
}
