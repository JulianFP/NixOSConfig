{ inputs, ... }:

let
  pkgs-unstable = (
    import inputs.nixpkgs {
      system = "x86_64-linux";
    }
  );
in
final: prev: {
  iamb = pkgs-unstable.iamb;
}
