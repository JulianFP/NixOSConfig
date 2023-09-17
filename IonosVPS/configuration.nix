# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ modulesPath, config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  #openssh config
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
  users.users.root.openssh.authorizedKeys.keyFiles = [
    ../id_rsa.pub
  ];

  networking = {
    hostName = "IonosVPS"; #define hostname
    networkmanager.enable = true;
    enableIPv6 = false;
    nameservers = [
      "212.227.123.16"
      "212.227.123.17"
    ];
    interfaces = {
      ens6 = {
        ipv4.addresses = [{
          address = "85.215.33.173";
          prefixLength = 32;
        }];
        useDHCP = false;
      };
    };
    defaultGateway = {
      address = "85.215.33.1";
      interface = "ens6";
    };
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "de-latin1";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
  ];

  #vm stuff
  services.qemuGuest.enable = true;

    # enable flakes and nix-command
  nix = {
    package = pkgs.nixFlakes;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
