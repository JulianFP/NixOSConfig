{ inputs, ... }:

let
  pkgs-unstable = (
    import inputs.nixpkgs {
      system = "x86_64-linux";
    }
  );
in
final: prev: {
  stevenblack-blocklist = pkgs-unstable.stevenblack-blocklist;
}
