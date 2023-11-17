{ modulesPath, pkgs, hostName, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      (modulesPath + "/installer/scan/not-detected.nix")
      (modulesPath + "/profiles/qemu-guest.nix")
    ];

  #openssh config
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    extraConfig = ''
      StreamLocalBindUnlink yes
    '';
  };
  users.users.root.openssh.authorizedKeys.keyFiles = [
    ../publicKeys/id_rsa.pub
  ];

  #vm stuff
  services.qemuGuest.enable = true;
}
