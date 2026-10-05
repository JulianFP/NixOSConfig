{ config, hostName, ... }:

let
  mountPoint = "/mnt/backupHDD";
in
{
  sops.secrets."restic-server" = {
    sopsFile = ../secrets/${hostName}/restic.yaml;
    owner = "restic";
  };

  services.restic.server = {
    enable = true;
    dataDir = mountPoint;
    privateRepos = true;
    prometheus = true;
    htpasswd-file = config.sops.secrets."restic-server".path;
  };

  networking.firewall.allowedTCPPorts = [ 8000 ];
  services.nebula.networks."serverNetwork".firewall.inbound = [
    {
      port = 8000;
      proto = "tcp";
      group = "server";
    }
  ];

  #make sure that backups can only be created onto the mounted backup HDD, not the boot drive!
  systemd.services.restic-rest-server.unitConfig.RequiresMountsFor = mountPoint;
  systemd.sockets.restic-rest-server.unitConfig.RequiresMountsFor = mountPoint;
}
