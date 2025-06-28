{ pkgs, ... }:
{
  services.tang = {
    enable = true;
    listenStream = [
      "192.168.10.30:7654"
    ];
    ipAddressAllow = [
      "192.168.10.0/24"
    ];
  };
  environment.persistence."/persist".directories = [
    "/var/lib/tang"
  ];
  networking.firewall.allowedTCPPorts = [ 7654 ];

  #also add wakeup script for JuliansPC
  environment.defaultPackages = [
    (pkgs.writeShellScriptBin "wakeupJuliansPC" ''
      if systemctl is-active -q tangd.socket; then
        ${pkgs.wakeonlan}/bin/wakeonlan -i 192.168.10.255 d8:43:ae:a2:ad:3c
      else
        echo "tang server not running, didn't wake up PC!"
      fi
    '')
  ];
}
