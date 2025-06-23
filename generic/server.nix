{
  modulesPath,
  lib,
  hostName,
  config,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    (modulesPath + "/installer/scan/not-detected.nix")
    ./common.nix
    ./nebula.nix
    ./ssh.nix
    ./promtail.nix # promtail to get all system logs
  ];

  #automatic maintenance services
  #automatic garbage collect to avoid storage depletion by autoUpgrade
  nix.gc = {
    automatic = true;
    dates = "03:00";
    randomizedDelaySec = "30min";
    options = "--delete-older-than 30d";
  };
  #automatic optimisation of nix store to save even more storage
  nix.optimise = {
    automatic = true;
    dates = [ "03:45" ];
  };
  #automatic upgrade is configured in proxmoxVM.nix since some servers (e.g. IonosVPS) can't build their nixos config locally

  #enable prometheus node exporter so that it can be scraped by mainserver Prometheus instance
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    listenAddress =
      if (hostName == "mainserver") then
        "localhost"
      else
        config.myModules.nebula."serverNetwork".ipMap."${hostName}";
    enabledCollectors = [
      #these are used by the Grafana dashboard
      "systemd"
      "processes"
    ];
  };

  networking.firewall.allowedTCPPorts = [ 9100 ];
  services.nebula.networks."serverNetwork".firewall.inbound = [
    {
      #open up loki port to all servers so that they can push their logs too
      port = 9100;
      proto = "tcp";
      host = config.myModules.nebula."serverNetwork".ipMap.mainserver;
    }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
