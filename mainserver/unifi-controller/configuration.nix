{ inputs, config, ... }:

let
  pkgs-unstable = (
    import inputs.nixpkgs {
      system = "x86_64-linux";
      config.allowUnfreePredicate = config.nixpkgs.config.allowUnfreePredicate;
    }
  );
in
{
  services.unifi = {
    enable = true;
    unifiPackage = pkgs-unstable.unifi;
  };
}
