{ config, lib, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./nebula.nix
  ];

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  }; 
  users.users.root.openssh.authorizedKeys.keyFiles = [
    ../id_rsa.pub
  ];

  networking = {
    hostName = "IonosVPS";
    enableIPv6 = false;
    domain = "";
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
  ];

  services.qemuGuest.enable = true;

  time.timeZone = "Europe/Berlin";

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;

  nix = {
    package = pkgs.nixFlakes;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };

  system.stateVersion = "23.05";
}
