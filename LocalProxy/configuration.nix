{ config, pkgs, ... }:

{
    #openssh host key
  sops.secrets."openssh/LocalProxy" = {
    sopsFile = ../secrets/LocalProxy/ssh.yaml;
  };
  services.openssh.hostKeys = [
    {
      path =  config.sops.secrets."openssh/LocalProxy".path;
      type = "ed25519";
    }
  ];
  users.users.root.openssh.authorizedKeys.keyFiles = [
    ../publicKeys/IonosVPS.pub
  ];


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
  sops.template."curlDDNS.sh".content = ''
    #! /usr/bin/env nix-shell
    #! nix-shell -i bash --packages curl 
    curl -X GET https://ipv4.api.hosting.ionos.com/dns/v1/dyndns?q=${config.sops.placeholder.ddns-1}
  '';
  services.cron.systemCronJobs = [
    "*/5 * * * * ${config.sops.templates."curlDDNS.sh".path}"
  ];
}
