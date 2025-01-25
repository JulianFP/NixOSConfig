{ config, lib, hostName, ... }:

{
  #openssh client key config
  sops.secrets."openssh/${hostName}" = {
    sopsFile = ../secrets/${hostName}/ssh.yaml;
    path = "/root/.ssh/${hostName}";
  };

  #openssh host key
  sops.secrets."openssh-host/${hostName}" = {
    sopsFile = ../secrets/${hostName}/ssh.yaml;
  };

  services.openssh.hostKeys = lib.mkForce [
    {
      path =  config.sops.secrets."openssh-host/${hostName}".path;
      type = "ed25519";
    }
  ];

  users.users.root.openssh.authorizedKeys.keyFiles = [
    ../publicKeys/IonosVPS.pub
    ../publicKeys/mainserver.pub
  ];
}
