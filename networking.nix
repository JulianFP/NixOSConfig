{ config, lib, pkgs, inputs, ...}:

{
  networking = {
    hostName = "JuliansFramework"; # Define your hostname.
    networkmanager.enable = true;  # Easiest to use and most distros use this by default.

    # rpfilter allow Wireguard traffic (see https://nixos.wiki/wiki/WireGuard#Setting_up_WireGuard_with_NetworkManager)
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

    #vlan config
    vlans = {
      vlan3 = {
        id = 3;
        interface = "enp0s13f0u4u3";
      };
    };
    interfaces.vlan3.ipv4.addresses = [{
      address = "192.168.3.50";
      prefixLength = 24;
    }];
  };

  # Wireguard and other VPNs are added through networkmanager and not declaratevely through Nix
}
