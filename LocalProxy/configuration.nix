{ config, ... }:

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
    ];
  };
}
