inputs: systems:

let
  mkConfig = import ./mkConfig.nix;
  mkSystem = attributes@{stable ? true, ...}: 
    let
      nixpkgs = if stable then inputs.nixpkgs-stable else inputs.nixpkgs;
    in nixpkgs.lib.nixosSystem (mkConfig (attributes // {inherit inputs nixpkgs stable;}));
in builtins.mapAttrs (name: value: mkSystem ({ hostName = name; } // value)) systems
