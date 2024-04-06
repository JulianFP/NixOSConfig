{ config, hostName, ... }:

{
  sops.secrets."project-W/env-file" = {
    sopsFile = ../secrets/${hostName}/project-W.yaml;
  };

  services.project-W-backend = {
    enable = true;
    hostName = "project-w.partanengroup.de";
    settings = {
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
        port = "22";
        proto = "tcp";
        group = "admin";
      }
      {
        port = "80";
        proto = "tcp";
        group = "edge";
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [ 80 ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
