{ lib, hostName, ... }:

#warning: This currently only works together with the generic/ssh-sops-key.nix config and only for the root user!
{
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "*".userKnownHostsFile = "~/.ssh/known_hosts ~/.ssh/known_hostsHM";
      "IonosVPS" = {
        hostname = "10.28.128.1";
        user = "root";
        identityFile = "/root/.ssh/${hostName}";
      };
      "mainserver" = {
        hostname = "10.28.128.3";
        user = "root";
        identityFile = "/root/.ssh/${hostName}";
      };
    };
  };

  home.file.".ssh/known_hostsHM" = {
    text = lib.strings.concatLines [
      ("10.28.128.1 " + builtins.readFile ../publicKeys/IonosVPS-host-rsa.pub)
      ("10.28.128.1 " + builtins.readFile ../publicKeys/IonosVPS-host-ed25519.pub)
      ("10.28.128.3 " + builtins.readFile ../publicKeys/mainserver-host-rsa.pub)
      ("10.28.128.3 " + builtins.readFile ../publicKeys/mainserver-host-ed25519.pub)
    ];
  };
}
