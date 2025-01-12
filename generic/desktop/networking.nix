{ lib, pkgs, config, hostName, ... }:

let
  nebulaSystemdService = config.systemd.services."nebula@serverNetwork";
  envFile = "/persist/nebulaOverwriter/envFile";
in 
{
  networking = {
    hostName = hostName; # Define your hostname.
    networkmanager.enable = true;

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
  #make nebula config adjustable through toggleNebulaUnsafeRoutes bash package that can be found in ../packages/shellScriptBin/nebulaRoutes.nix
  #this is necessary to adjust unsafe_routes on the fly through a quick terminal command without having to change the NixOS and rebuilding all the time
  systemd.services."nebula-custom_serverNetwork" = {
    description = "Adjusted Nebula VPN service for serverNetwork that works together with the nebulaOverwriter python script";
    after = [ "nebula@serverNetwork.service" "basic.target" "network.target" ];
    wantedBy = [ "multi-user.target" "nebula@serverNetwork.service" ];
    conflicts = [ "nebula@serverNetwork.service" ];
    unitConfig = {
      StartLimitIntervalSec = 0;
      ConditionPathExists = envFile;
    };
    serviceConfig = lib.mkMerge [ nebulaSystemdService.serviceConfig {
      EnvironmentFile = envFile;
      ExecStart = lib.mkForce "${config.services.nebula.networks."serverNetwork".package}/bin/nebula -config \"$NEBULA_CONFIG_PATH\"";
    }];
  };

  environment.systemPackages = [
    (import ../packages/shellScriptBin/vlan.nix {inherit pkgs;})
    (import ../packages/shellScriptBin/nebulaRoutes.nix {
      inherit pkgs envFile;
      oldConfigFile = builtins.head (builtins.match "^.*(\/nix\/store\/.{32}-nebula-config.*)$" nebulaSystemdService.serviceConfig.ExecStart);
    })
  ];
}
