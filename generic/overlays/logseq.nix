{ inputs, ... }:
let
  pkgs-stable = (import inputs.nixpkgs-stable {
    system = "x86_64-linux"; 
    config.permittedInsecurePackages = [ "electron-27.3.11" ];
  });
in 
final: prev: {
  logseq = pkgs-stable.logseq;
}
