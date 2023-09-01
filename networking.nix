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
  };

  # Wireguard and other VPNs are added through networkmanager and not declaratevely through Nix

  # nebula config
  services.nebula.networks."serverNetwork" = {
    enable = false;
    ca = ~/.nebula/ca.crt;
    key = ~/.nebula/JuliansFramework.key;
    cert = ~/.nebula/JuliansFramework.key;
    listen.port = 51821;
    lighthouses = [ "48.42.0.1" ];
    staticHostMap = {
      "48.42.0.1" = [
        "82.165.49.241:51821"
      ];
    };
    settings = {
      cipher = "aes";
      punchy = {
        punch = true;
        respond = true;
      };
    };
    firewall = {
      outbound = [
        {
          host = "any";
          port = "any";
          proto = "any";
        }
      ];
      inbound = [
        {
          port = "any";
          proto = "icmp";
          host = "any";
        }
      ];
    };
  };
}
