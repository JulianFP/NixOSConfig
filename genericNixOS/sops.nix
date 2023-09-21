{ ... }:

# requires a working gnupg home at /root/.gnupg! Set it up with home-manager
#for servers you can use genericHomeManager/gnupg.nix
#gets imported by genericNixOS/nebula.nix
{
  sops = {
    defaultSopsFile = ../secrets/example.yaml;
    gnupg.home = "/root/.gnupg/";
    gnupg.sshKeyPaths = [];
    secrets.example-key = {};
  };
}
