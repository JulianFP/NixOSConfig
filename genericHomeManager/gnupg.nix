{ ... }:

{
  programs.gpg = {
    enable = true;
    publicKeys = [{
      source = ../../../gpg_yubikey.asc;
      trust = 5;
    }];
    settings.no-autostart = true;
  };

  home.stateVersion = "23.05";
  programs.home-manager.enable = true;
}
