{ ... }:

{
  services.thelounge = {
    enable = true;
    extraConfig.https = {
      enable = true;
      key = "/persist/domain.key";
      certificate = "/persist/domain.crt";
    };
  };
  environment.persistence."/persist/backMeUp" = {
    hideMounts = true;
    directories = [
      "/var/lib/thelounge"
    ];
  };

  networking.firewall.allowedTCPPorts = [ 9000 ];
  services.nebula.networks."serverNetwork".firewall.inbound = [
    {
      port = 9000;
      proto = "tcp";
      group = "julian";
    }
  ];
}
