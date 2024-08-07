{ hostName, ... }:

{
  networking = {
    hostName = hostName; # Define your hostname.
    networkmanager = {
      enable = true;
      enableStrongSwan = true; # For l2tp vpn
    };

    # rpfilter allow Wireguard traffic (see https://wiki.nixos.org/wiki/WireGuard#Setting_up_WireGuard_with_NetworkManager)
    firewall = { 
      # if packets are still dropped, they will show up in dmesg
      logReversePathDrops = true;
      # wireguard trips rpfilter up
      extraCommands = ''
        ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --sport 51820 -j RETURN
        ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --dport 51820 -j RETURN
      '';
      extraStopCommands = ''
        ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --sport 51820 -j RETURN || true
        ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --dport 51820 -j RETURN || true
      '';
    };
  };

  #for l2tp vpn
  services.xl2tpd.enable = true;
  services.strongswan = {
    enable = true;
    secrets = [ "ipsec.d/ipsec.nm-l2tp.secrets" ]; #ensure that it does not write secrets on read-only filesystem
  };

  #setup nebula unsafe_routes
  /*
  services.nebula.networks."serverNetwork".settings.tun.unsafe_routes = [
    {
      route = "192.168.3.0/24";
      via = "48.42.0.3";
    }
    {
      route = "192.168.1.0/24";
      via = "48.42.0.3";
    }
    {
      route = "192.168.10.0/24";
      via = "48.42.0.4";
    }
  ];
  */

  # vlan config is done with script in ./shellScriptBin/vlan.nix
}
