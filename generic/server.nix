{ modulesPath, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./common.nix
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

  #automatic upgrade. Pulls newest commits from github daily. Relies on my updating the flake inputs (I want that to be manual and tracked by git)
  system.autoUpgrade = {
    enable = true;
    flake = "github:JulianFP/NixOSConfig";
    dates = "03:00";
    randomizedDelaySec = "60min";
    allowReboot = true;
    rebootWindow = {
      lower = "03:00";
      upper = "05:00";
    };

  };
}
