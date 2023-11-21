{ userName, ... }:

{
  #get general public key in place
  home.file.".ssh/id_rsa.pub" = {
    source = ../publicKeys/id_rsa.pub;
  };

  #ssh support
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "Ionos" = {
        hostname = "82.165.49.241";
	      user = "root";
      };
    };
    forwardAgent = true;
    extraConfig = ''
      Match host * exec "gpg-connect-agent UPDATESTARTUPTTY /bye"
    '';
  };
  systemd.user.sessionVariables = {
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh";
  };
  programs.zsh.sessionVariables.GPG_TTY = "$(tty)";

  #gpg setup
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    defaultCacheTtl = 300;
    defaultCacheTtlSsh = 300;
    maxCacheTtl = 3600;
    maxCacheTtlSsh = 3600;
    pinentryFlavor = if userName == "root" then "tty" else "qt";
    extraConfig = ''
      ttyname $GPG_TTY
    '';
  };
  programs.gpg = {
    enable = true;
    scdaemonSettings = {
      disable-ccid = true;
      reader-port = "Yubico Yubi";
    };
    publicKeys = [{
      source = ../publicKeys/gpg_yubikey.asc;
      trust = 5;
    }];
  };
}
