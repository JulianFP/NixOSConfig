{ pkgs, ... }:
{
  services.tang = {
    enable = true;
    listenStream = [
      "192.168.0.30:7654"
    ];
    ipAddressAllow = [
      "192.168.0.0/24"
    ];
  };
  systemd.sockets.tangd.socketConfig.FreeBind = "yes"; # required when listenStream is set
  environment.persistence."/persist".directories = [
    "/var/lib/private/tang"
  ];
  networking.firewall.allowedTCPPorts = [ 7654 ];

  #also add wakeup script for JuliansPC
  environment.defaultPackages = [
    (pkgs.writeShellScriptBin "wakeupJuliansPC" ''
      if systemctl is-active -q tangd.socket; then
        ${pkgs.wakeonlan}/bin/wakeonlan -i 192.168.0.255 d8:43:ae:a2:ad:3c
      else
        echo "tang server not running, didn't wake up PC!"
      fi
    '')
  ];
}
