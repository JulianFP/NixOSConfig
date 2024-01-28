{ config, pkgs, ... }:

{
  services.nebula.networks."serverNetwork" = {
    firewall.inbound = [
      {
        port = "22";
        proto = "tcp";
        group = "admin";
      }
      {
        port = "22";
        proto = "tcp";
        group = "edge";
      }
    ];
  };

  #ddns update service (see https://www.ionos.de/hilfe/domains/ip-adresse-konfigurieren/dynamisches-dns-ddns-einrichten-bei-company-name/?source=helpandlearn#c170862)
  sops.secrets.ddns-1 = {
    sopsFile = ../secrets/LocalProxy/ddns.yaml;
  };
  sops.templates."curlDDNS.sh" = {
    content = ''
      #! ${pkgs.bash}/bin/bash
      ${pkgs.curl}/bin/curl -X GET https://ipv4.api.hosting.ionos.com/dns/v1/dyndns?q=${config.sops.placeholder.ddns-1}
    '';
    mode = "0550";
  };
  systemd.timers."ddns" = {
    wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1m";
        OnUnitActiveSec = "1m";
        Unit = "ddns.service";
      };
  };
  systemd.services."ddns" = {
    script = ''
      ${config.sops.templates."curlDDNS.sh".path}
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
