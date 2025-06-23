{ inputs, hostName, ... }:

#requires you to manually update .sops.yaml file if key got generated
#gets imported by genericNixOS/nebula.nix
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    defaultSopsFile = ../secrets/general.yaml;
    age.keyFile = "/persist/sops-nix/key.txt";
    age.generateKey = true; # generate key above if it does not exist yet (has to be added manually to .sops.yaml)
    secrets.example-key = { };
  };
}
