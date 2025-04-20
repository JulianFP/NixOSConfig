{ config, lib, hostName, ... }:

{
  sops.secrets = {
    #openssh client key config
    "openssh/${hostName}" = {
      sopsFile = ../secrets/${hostName}/ssh.yaml;
      path = "/root/.ssh/${hostName}";
    };

    #openssh host keys
    "openssh-host/${hostName}-ed25519" = {
      sopsFile = ../secrets/${hostName}/ssh.yaml;
    };
    "openssh-host/${hostName}-rsa" = {
      sopsFile = ../secrets/${hostName}/ssh.yaml;
    };
  };

  services.openssh.hostKeys = lib.mkForce [
    {
      bits = 4096;
      path =  config.sops.secrets."openssh-host/${hostName}-rsa".path;
      type = "rsa";
    }
    {
      path =  config.sops.secrets."openssh-host/${hostName}-ed25519".path;
      type = "ed25519";
    }
  ];

  users.users.root.openssh.authorizedKeys.keyFiles = [
    ../publicKeys/IonosVPS.pub
    ../publicKeys/mainserver.pub
  ];
}
