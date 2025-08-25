{ config, hostName, ... }:

{
  sops.secrets."restic-server" = {
    sopsFile = ../secrets/${hostName}/restic.yaml;
    owner = "restic";
  };

  services.restic.server = {
    enable = true;
    dataDir = "/mnt/backupHDD";
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
}
