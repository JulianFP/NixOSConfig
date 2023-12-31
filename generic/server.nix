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
  #automatic garbage collect to avoid storage depletion by autoUpgrade
  nix.gc = {
    automatic = true;
    dates = "04:00";
    randomizedDelaySec = "60min";
    options = "--delete-older-than 30d";
  };
}
