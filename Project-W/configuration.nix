{ config, hostName, ... }:

{
  sops.secrets."project-W/env-file" = {
    sopsFile = ../secrets/${hostName}/project-W.yaml;
  };

  services.project-W-backend = {
    enable = true;
    hostName = "project-w.partanengroup.de";
    settings = {
      databasePath = "/persist/backMeUp/project-w/database";
      clientURL = "https://project-w.partanengroup.de/#";
      smtpServer = {
        domain = "mail.partanengroup.de";
        port = 587;
        secure = "starttls";
        senderEmail = "admin@partanengroup.de";
        username = config.services.project-W-backend.settings.smtpServer.senderEmail;
      };
    };
    envFile = config.sops.secrets."project-W/env-file".path;
  };
  services.project-W-frontend = {
    enable = true;
    hostName = config.services.project-W-backend.hostName;
  };

  services.nebula.networks."serverNetwork" = {
    firewall.inbound = [
      {
        port = "80";
        proto = "tcp";
        group = "edge";
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [ 80 ];
}
