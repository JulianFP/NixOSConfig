{ config, pkgs, ... }:

{
  imports = [
    ./buildIonosVPS.nix
  ];

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
}
