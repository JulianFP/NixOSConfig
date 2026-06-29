{ lib, hostName, ... }:

#warning: This currently only works together with the generic/ssh-sops-key.nix config and only for the root user!
{
  programs.ssh = {
    enable = true;
    settings = {
      "*".UserKnownHostsFile = "~/.ssh/known_hosts ~/.ssh/known_hostsHM";
      "IonosVPS" = {
        HostName = "10.28.128.1";
        User = "root";
        IdentityFile = "/root/.ssh/${hostName}";
      };
      "mainserver" = {
        HostName = "10.28.128.3";
        User = "root";
        IdentityFile = "/root/.ssh/${hostName}";
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
