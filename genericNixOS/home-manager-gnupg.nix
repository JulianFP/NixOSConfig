{ inputs, ... }:

{
  imports = [
    inputs.home-manager-stable.nixosModules.home-manager 
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.root = {
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
        };
      };
    }
  ];
}
