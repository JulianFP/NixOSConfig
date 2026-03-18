{
  inputs,
  permittedInsecurePackages,
  permittedUnfreePackages,
  ...
}:

let
  pkgs-unstable = (
    import inputs.nixpkgs {
      system = "x86_64-linux";
      config = {
        inherit permittedInsecurePackages;
        allowUnfreePredicate = pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) permittedUnfreePackages;
      };
    }
  );
in
final: prev: {
  iamb = pkgs-unstable.iamb;
  zoom-us = pkgs-unstable.zoom-us;
}
