{ pkgs, config, ... }:

# yubikey config shared by julian and root user of JuliansFramework
{
  #get general public key in place
  home.file.".ssh/id_ed25519.pub" = {
    source = ../publicKeys/yubikey-new_ssh.pub;
  };

  #ssh support
  programs.ssh = {
    enable = true;
    matchBlocks."*" = {
      forwardAgent = true;
      #needed for terminal based pinentry to always appear in current terminal window
      match = ''
        host * exec "gpg-connect-agent UPDATESTARTUPTTY /bye"
      '';
    };
  };

  #gpg setup
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    #integration sets GPG_TTY and executes UPDATESTARTUPTTY at init
    enableBashIntegration = true;
    enableZshIntegration = true;
    #cache is valid for 5min (countdown resets when using cache)
    defaultCacheTtl = 300;
    defaultCacheTtlSsh = 300;
    #cache is at most valid for 1h (this countdown doesn't reset when using cache)
    maxCacheTtl = 3600;
    maxCacheTtlSsh = 3600;

    pinentry.package = if config.home.username == "root" then pkgs.pinentry-tty else pkgs.pinentry-qt;
  };
  programs.gpg = {
    enable = true;
    scdaemonSettings = {
      disable-ccid = true;
      reader-port = "Yubico Yubi";
    };
    publicKeys = [
      {
        source = ../publicKeys/yubikey_gpg.asc;
        trust = 5;
      }
      {
        source = ../publicKeys/yubikey-new_gpg.asc;
        trust = 5;
      }
    ];
  };
}
