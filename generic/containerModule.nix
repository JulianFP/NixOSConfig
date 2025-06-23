{
  lib,
  config,
  pkgs,
  inputs,
  hostName,
  ...
}:

let
  cfg = config.myModules.container;
  enabledContainers = lib.filterAttrs (n: v: v.enable) cfg.containers;
  nebulaSubnet = "48.42.0.0/16";
  nebulaGateway = "48.42.0.5";
  nebulaContainerIPNetId = "48.42.1";
in
{
  imports = [
    ./nebulaModule.nix
  ];

  options.myModules.container = {
    externalNetworkInterface = lib.mkOption {
      type = lib.types.str;
      description = "The external network interface that is used for the default route of this machine (where it gets internet connection over)";
    };
    containers = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Whether this container should be enabled";
            };
            enableSops = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether sops-nix should be enabled inside the container";
            };
            hostID = lib.mkOption {
              type = lib.types.ints.u8;
              description = "Host ID of local and nebula IP address (equivalent to what vmID was for Proxmox VMs before)";
            };
            nebulaOnly = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether this container should only have access to its nebula interface (aside from loopback) and set its default route to it (route everything over nebula)";
            };
            openTCPPorts = lib.mkOption {
              type = lib.types.listOf lib.types.port;
              default = [ ];
              description = "List of TCP ports that should be opened at container (for both NixOS firewall and nebula firewall for edge group)";
            };
            openUDPPorts = lib.mkOption {
              type = lib.types.listOf lib.types.port;
              default = [ ];
              description = "List of UDP ports that should be opened at container (for both NixOS firewall and nebula firewall for edge group)";
            };
            forwardPorts = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether to forward opened udp and tcp ports to the local external interface using dnat";
            };
            permittedUnfreePackages = lib.mkOption {
              type = lib.types.listOf lib.types.singleLineStr;
              default = [ ];
              description = "List of unfree package names that should be allowed inside this container";
            };
            additionalBindMounts = lib.mkOption {
              type = lib.types.attrs;
              default = { };
              description = "Bind mounts in addition to the one to /persist/backMeUp and /persist/sops-nix";
            };
            additionalContainerConfig = lib.mkOption {
              type = lib.types.attrs;
              default = { };
              description = "Additional configuration that will be put into the NixOS module under containers.<name>, e.g. to configure extra capabilities";
            };
            config = lib.mkOption {
              type = lib.types.path;
              description = "Path to config file. Note that some things like stateVersion and DNS fixes are already being configured by this module for all containers.";
            };
          };
        }
      );
    };
  };

  config = lib.mkIf (enabledContainers != { }) {
    #setup nebula connection for every container
    myModules.nebula = builtins.mapAttrs (n: v: {
      secretHostName = hostName;
      installHostName = n;
    }) enabledContainers;
    services.nebula.networks = (
      builtins.mapAttrs (n: v: {
        settings.tun.unsafe_routes = lib.mkIf v.nebulaOnly [
          {
            route = "0.0.0.0/0";
            via = "48.42.0.5";
            install = false;
          }
        ];
        firewall.inbound =
          (builtins.concatLists (
            builtins.map (port: [
              {
                port = port;
                proto = "tcp";
                group = "edge";
              }
              {
                #allow admins to bypass reverse proxy for debugging/maintenance purposes
                port = port;
                proto = "tcp";
                group = "admin";
              }
            ]) v.openTCPPorts
          ))
          ++ (builtins.concatLists (
            builtins.map (port: [
              {
                port = port;
                proto = "udp";
                group = "edge";
              }
              {
                port = port;
                proto = "udp";
                group = "admin";
              }
            ]) v.openUDPPorts
          ));
      }) enabledContainers
    );

    #networking stuff that all containers share. systemd service templates
    #every container gets their own network namespace, nebula interface and optionally veth pair
    #taken from https://uint.one/posts/all-internet-over-wireguard-using-systemd-networkd-on-nixos/ and adapted for my use case with nebula
    networking = {
      nftables.enable = true; # make sure again that we really use nftables because of below
      firewall = {
        allowedTCPPorts = (
          builtins.concatLists (
            lib.mapAttrsToList (n: v: if v.forwardPorts then v.openTCPPorts else [ ]) enabledContainers
          )
        );
        allowedUDPPorts = (
          builtins.concatLists (
            lib.mapAttrsToList (n: v: if v.forwardPorts then v.openUDPPorts else [ ]) enabledContainers
          )
        );
      };
      nat = {
        enable = true;
        internalInterfaces = [ "ve-*" ]; # the * wildcard syntax is specific to nftables, use + if switching back to iptables!
        externalInterface = cfg.externalNetworkInterface;
        enableIPv6 = false;
        forwardPorts = (
          builtins.concatLists (
            lib.mapAttrsToList (
              n: v:
              if v.forwardPorts then
                (
                  (builtins.map (tcp_port: {
                    destination = "10.42.42.${builtins.toString v.hostID}:${builtins.toString tcp_port}";
                    proto = "tcp";
                    sourcePort = tcp_port;
                  }) v.openTCPPorts)
                  ++ (builtins.map (udp_port: {
                    destination = "10.42.42.${builtins.toString v.hostID}:${builtins.toString udp_port}";
                    proto = "udp";
                    sourcePort = udp_port;
                  }) v.openUDPPorts)
                )
              else
                [ ]
            ) enabledContainers
          )
        );
      };
    };
    systemd = lib.mkMerge (
      lib.mapAttrsToList (
        n: v:
        let
          shortenedN = builtins.substring 0 11 n;
        in
        {
          services =
            {

              "netns@${n}" = {
                description = "${n} containers veth network namespace";
                serviceConfig = with pkgs; {
                  Type = "oneshot";
                  RemainAfterExit = true;
                  ExecStart = "${iproute2}/bin/ip netns add ${shortenedN}";
                  ExecStop = "${iproute2}/bin/ip netns del ${shortenedN}";
                };
              };
              "lo@${n}" = {
                description = "loopback in ${n} containers network namespace";

                bindsTo = [ "netns@${n}.service" ];
                after = [ "netns@${n}.service" ];

                serviceConfig = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                  ExecStart =
                    let
                      start =
                        with pkgs;
                        writeShellScript "lo-up" ''
                          set -e

                          ${iproute2}/bin/ip -n $1 addr add 127.0.0.1/8 dev lo
                          ${iproute2}/bin/ip -n $1 link set lo up
                        '';
                    in
                    "${start} ${shortenedN}";
                  ExecStopPost = with pkgs; "${iproute2}/bin/ip -n ${shortenedN} link del lo";
                };
              };
              "veth@${n}" = {
                description = "virtual ethernet network interface between the main and ${n} containers network namespaces";

                bindsTo = [ "netns@${n}.service" ];
                after = [ "netns@${n}.service" ];

                serviceConfig = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                  ExecStart =
                    let
                      start =
                        with pkgs;
                        writeShellScript "veth-${n}-up" ''
                          set -e
                          ${iproute2}/bin/ip link add ve-${shortenedN} type veth peer name eth-${shortenedN}
                          ${iproute2}/bin/ip link set eth-${shortenedN} netns ${shortenedN}
                          ${iproute2}/bin/ip -n ${shortenedN} link set dev eth-${shortenedN} name eth-lan
                          ${iproute2}/bin/ip addr add 10.42.42.1/32 dev ve-${shortenedN}
                          ${iproute2}/bin/ip -n ${shortenedN} addr add 10.42.42.${builtins.toString v.hostID}/32 dev eth-lan
                          ${iproute2}/bin/ip link set ve-${shortenedN} up
                          ${iproute2}/bin/ip -n ${shortenedN} link set eth-lan up
                          ${iproute2}/bin/ip route add 10.42.42.${builtins.toString v.hostID}/32 dev ve-${shortenedN}
                          ${iproute2}/bin/ip -n ${shortenedN} route add 10.42.42.1/32 dev eth-lan
                          ${iproute2}/bin/ip -n ${shortenedN} route add default via 10.42.42.1
                        '';
                    in
                    "${start}";
                  ExecStopPost =
                    let
                      stop =
                        with pkgs;
                        writeShellScript "veth-down" ''
                          ${iproute2}/bin/ip -n $1 link del eth-lan
                          ${iproute2}/bin/ip link del ve-$1
                        '';
                    in
                    "${stop} ${shortenedN}";
                };
              };
              "nebulaVeth@${n}" =
                let
                  nebulaSystemdService = config.systemd.services."nebula@${n}";
                in
                {
                  description = "nebula network interface in ${n} containers network namespace (same one where veth is in)";

                  bindsTo = [
                    "netns@${n}.service"
                    "veth@${n}.service"
                  ];
                  wants = [
                    "network-online.target"
                    "nss-lookup.target"
                  ];
                  after = [
                    "netns@${n}.service"
                    "veth@${n}.service"
                    "network-online.target"
                    "nss-lookup.target"
                  ];

                  unitConfig.StartLimitIntervalSec = 0;

                  serviceConfig =
                    with pkgs;
                    lib.mkMerge [
                      nebulaSystemdService.serviceConfig
                      {
                        ExecStart = lib.mkForce "${iproute2}/bin/ip netns exec ${shortenedN} ${nebulaSystemdService.serviceConfig.ExecStart}";
                        CapabilityBoundingSet = lib.mkForce [
                          "CAP_SYS_ADMIN"
                          "CAP_NET_ADMIN"
                        ];
                        AmbientCapabilities = lib.mkForce [
                          "CAP_SYS_ADMIN"
                          "CAP_NET_ADMIN"
                        ];
                        RestrictNamespaces = lib.mkForce false;
                        RestrictSUIDSGID = lib.mkForce false;
                      }
                    ];
                };

              #overwriting default systemd services
              "container@${n}" = {
                requires =
                  if v.nebulaOnly then
                    [
                      "lo@neb-${n}.service"
                      "moveNebNS@${n}.service"
                    ]
                  else
                    [
                      "lo@${n}.service"
                      "nebulaVeth@${n}.service"
                    ];
              };
              "nebula@${n}".enable = lib.mkForce false; # we have our own systemd service
            }
            // lib.optionalAttrs v.nebulaOnly {
              "netns@neb-${n}" = {
                description = "${n} containers nebula-only network namespace";
                serviceConfig = with pkgs; {
                  Type = "oneshot";
                  RemainAfterExit = true;
                  ExecStart = "${iproute2}/bin/ip netns add neb-${shortenedN}";
                  ExecStop = "${iproute2}/bin/ip netns del neb-${shortenedN}";
                };
              };
              "lo@neb-${n}" = {
                description = "loopback in ${n} containers nebula-only network namespace";

                bindsTo = [ "netns@${n}.service" ];
                after = [ "netns@${n}.service" ];

                serviceConfig = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                  ExecStart =
                    let
                      start =
                        with pkgs;
                        writeShellScript "lo-up" ''
                          set -e

                          ${iproute2}/bin/ip -n $1 addr add 127.0.0.1/8 dev lo
                          ${iproute2}/bin/ip -n $1 link set lo up
                        '';
                    in
                    "${start} neb-${shortenedN}";
                  ExecStopPost = with pkgs; "${iproute2}/bin/ip -n neb-${shortenedN} link del lo";
                };
              };
              "moveNebNS@${n}" = {
                description = "Move nebula interface of ${n} container into its own nebula-only network namespace";

                bindsTo = [
                  "netns@neb-${n}.service"
                  "nebulaVeth@${n}.service"
                ];
                after = [
                  "netns@neb-${n}.service"
                  "nebulaVeth@${n}.service"
                ];

                unitConfig = {
                  StartLimitBurst = 10;
                  StartLimitInterval = 11;
                };

                serviceConfig =
                  with pkgs;
                  let
                    nebulaInterfaceName = builtins.substring 0 15 "neb-${n}";
                  in
                  {
                    Type = "oneshot";
                    RemainAfterExit = true;
                    ExecStart =
                      let
                        start =
                          with pkgs;
                          writeShellScript "moveNebNS-${n}" ''
                            set -e
                            ${iproute2}/bin/ip -n ${shortenedN} link set ${nebulaInterfaceName} netns neb-${shortenedN}
                            ${iproute2}/bin/ip -n neb-${shortenedN} addr add ${nebulaContainerIPNetId}.${builtins.toString v.hostID} dev ${nebulaInterfaceName}
                            ${iproute2}/bin/ip -n neb-${shortenedN} link set ${nebulaInterfaceName} up
                            ${iproute2}/bin/ip -n neb-${shortenedN} route add ${nebulaSubnet} dev ${nebulaInterfaceName}
                            ${iproute2}/bin/ip -n neb-${shortenedN} route add default via ${nebulaGateway}
                          '';
                      in
                      "${start}";
                    ExecStop = "${iproute2}/bin/ip link set ${nebulaInterfaceName} ${shortenedN}";
                    Restart = "on-failure";
                    RestartSec = 1;
                  };
              };
            };
          #if the system uses systemd networkd, then mark our manually created veth interface as unmanaged so that networkd doesn't touch it
          network.networks."20-${n}-unmanaged" = lib.mkIf config.systemd.network.enable {
            matchConfig.Name = "ve-${shortenedN}";
            linkConfig.Unmanaged = true;
          };

          tmpfiles.settings."10-containerMountDirs" =
            lib.optionalAttrs v.enableSops {
              "/persist/sops-nix/${n}"."d" = {
                user = "root";
                group = "root";
                mode = "0755";
              };
            }
            // lib.mkMerge (
              lib.mapAttrsToList (n: v: {
                "${v.hostPath}"."d" = {
                  user = "root";
                  group = "root";
                  mode = "0755";
                };
              }) v.additionalBindMounts
            );
        }
      ) enabledContainers
    );

    containers = builtins.mapAttrs (
      n: v:
      let

        shortenedN = builtins.substring 0 11 n;
      in
      {
        autoStart = true;
        ephemeral = true;

        networkNamespace =
          if v.nebulaOnly then "/run/netns/neb-${shortenedN}" else "/run/netns/${shortenedN}";
        bindMounts =
          lib.optionalAttrs v.enableSops {
            "/persist/sops-nix" = {
              hostPath = "/persist/sops-nix/${n}";
              isReadOnly = false;
            };
          }
          // v.additionalBindMounts;

        specialArgs = {
          hostName = n;
          inputs = inputs;
        };

        config =
          { hostName, ... }:
          {
            imports = [
              v.config
              ./promtail.nix # to get systemd-journal out of container into loki
            ] ++ lib.lists.optional v.enableSops ./sops.nix;
            nixpkgs.config.allowUnfreePredicate =
              pkg: builtins.elem (lib.getName pkg) v.permittedUnfreePackages;
            networking = {
              hostName = hostName;
              useHostResolvConf = lib.mkForce false;
              firewall = {
                allowedTCPPorts = v.openTCPPorts;
                allowedUDPPorts = v.openUDPPorts;
              };
            };
            services.resolved.enable = true;
            system.stateVersion = config.system.stateVersion; # stateVersion of container should be the same as the one of the host
          };
      }
      // v.additionalContainerConfig
    ) enabledContainers;
  };
}
