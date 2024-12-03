{ lib, hostName, ... }:

#warning: This currently only works together with the generic/ssh-sops-key.nix config and only for the root user!
{
  programs.ssh = {
    enable = true;
    userKnownHostsFile = "~/.ssh/known_hosts ~/.ssh/known_hostsHM";
    matchBlocks = {
      "IonosVPS" = {
        hostname = "48.42.0.5";
        user = "root";
        identityFile = "/root/.ssh/${hostName}";
      };
      "LocalProxy" = {
        hostname = "48.42.1.130";
        user = "root";
        identityFile = "/root/.ssh/${hostName}";
      };
    };
  };

  home.file.".ssh/known_hostsHM" = {
    text = lib.strings.concatLines [
      ("48.42.0.5 " + builtins.readFile ../publicKeys/IonosVPS-host.pub)
      ("48.42.1.130 " + builtins.readFile ../publicKeys/LocalProxy-host.pub)
    ];
  };
}
