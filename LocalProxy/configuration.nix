{ config, ... }:

{
    #openssh host key
  sops.secrets."openssh/LocalProxy" = {
    sopsFile = ../secrets/LocalProxy/ssh.yaml;
  };
  sops.secrets."openssh/IonosVPS.pub" = {};
  services.openssh.hostKeys = [
    {
      path =  config.sops.secrets."openssh/LocalProxy".path;
      type = "ed25519";
    }
  ];
  users.users.root.openssh.authorizedKeys.keyFiles = [
    config.sops.secrets."openssh/IonosVPS.pub".path
  ];


  services.nebula.networks."serverNetwork" = {
    firewall.inbound = [
      {
        port = "22";
        proto = "tcp";
        group = "admin";
      }
    ];
  };
}
