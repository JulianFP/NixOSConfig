{ pkgs, ... }:

{
  networkmanager = {
    enable = true;
    enableStrongSwan = true;
  };

  services.xl2tpd.enable = true;
  services.strongswan = {
    enable = true;
    secrets = [ "ipsec.d/ipsec.nm-l2tp.secrets" ]; # ensure that it does not write secrets on read-only filesystem
  };

  environment.systemPackages = with pkgs; [
    networkmanager-l2tp
  ];
}
