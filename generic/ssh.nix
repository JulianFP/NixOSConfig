{ ... }:

# nebula firewall will be opened automatically in ./nebula.nix when services.openssh.enable is set to true
{
  #openssh config
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    extraConfig = ''
      StreamLocalBindUnlink yes
    '';
  };
  users.users.root.openssh.authorizedKeys.keyFiles = [
    ../publicKeys/id_rsa.pub #Yubikey
    ../publicKeys/backupSSHkey.pub #backup key in case Yubikey breaks
  ];
}
