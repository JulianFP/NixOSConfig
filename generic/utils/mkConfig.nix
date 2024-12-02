{ inputs, nixpkgs, hostName, stateVersion, system ? "x86_64-linux", stable, server ? false, desktop ? false, proxmoxVmID ? null, nebula ? true, boot ? 0, hasOwnModule ? true, homeManager ? true, systemModules ? [], homeManagerModules ? {}, permittedUnfreePackages ? [], permittedInsecurePackages ? [], overlays ? [], args ? {}}: 

let
  mkBasicConfig = import ./mkBasicConfig.nix;
  lib = nixpkgs.lib;
in {
  inherit system;
  pkgs = import nixpkgs {
    inherit system;
    inherit overlays;
    config = {
      inherit permittedInsecurePackages;
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) permittedUnfreePackages;
    };
  };
} // (mkBasicConfig {inherit inputs lib hostName stateVersion stable server desktop proxmoxVmID nebula boot hasOwnModule homeManager systemModules homeManagerModules args;})
