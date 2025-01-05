{ modulesPath, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./common.nix
      ./ssh.nix
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  #automatic maintenance services
  #automatic garbage collect to avoid storage depletion by autoUpgrade
  nix.gc = {
    automatic = true;
    dates = "03:00";
    randomizedDelaySec = "30min";
    options = "--delete-older-than 30d";
  };
  #automatic optimisation of nix store to save even more storage 
  nix.optimise = {
    automatic = true;
    dates = [ "03:45" ];
  };
  #automatic upgrade is configured in proxmoxVM.nix since some servers (e.g. IonosVPS) can't build their nixos config locally

  environment.variables.NIX_REMOTE = "daemon";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
