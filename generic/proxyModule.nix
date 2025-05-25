{ config, lib, pkgs, hostName, ... }:

# This is the setup for all my (reverse) proxies. Currently I have one in the cloud that is exposed to the internet (IonosVPS) and one locally that is not (mainserver)
# for the first one edge is set, for the second not. The first one syncs ssl certs to the second one
# The prometheus and loki stuff are mostly from here: https://github.com/Malfhas/caddy-grafana
let
  cfg = config.myModules.proxy;
in 
{
  options.myModules.proxy = {
    enable = lib.mkEnableOption ("Reverse-Proxy");
    proxies = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          destIP = lib.mkOption {
            type = lib.types.singleLineStr;
            description = "IP address to which this traffic should be forwarded";
          };
          destIPedge = lib.mkOption {
            type = lib.types.nullOr lib.types.singleLineStr;
            default = null;
            description = "Overwrite to destIP if isEdge is set to true.";
          };
          destPort = lib.mkOption {
            type = lib.types.port;
            description = "Port to which this traffic should be forwarded";
          };
          additionalConfig = lib.mkOption {
            type = lib.types.lines;
            default = '''';
            description = "Additional config added to the virtualHosts section (e.g. for adding additional locations)";
          };
        };
      });
    };
    isEdge = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this machine is an edge machine, e.g. accepting internet traffic on a VPS";
    };
    edgeHostName = lib.mkOption {
      type = lib.types.singleLineStr;
      description = "hostName of edge server so that local proxies know from where to pull certificates. This requires that ssh is configured with a matchBlock for this hostName.";
    };
    localDNS = {
      enable = lib.mkEnableOption ("Whether to enable a local DNS server for this machine that serves DNS entries of configured domains");
      localForwardIP = lib.mkOption {
        type = lib.types.singleLineStr;
        description = "IPv4 address to set A DNS entry of configured domains to";
      };
    };
  };

  config = let
    edgeNebulaIP = config.myModules.nebula."serverNetwork".ipMap."${cfg.edgeHostName}";
    hostNebulaIP = config.myModules.nebula."serverNetwork".ipMap."${hostName}";
  in lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = if cfg.localDNS.enable then config.services.unbound.enable else true;
        message = "Custom assertion: to use localDNS.enable in proxy module please configure unbound elsewhere. This just adds some entries to an existing unbound server";
      }
    ];

    sops.secrets."redis/caddy-server" = lib.mkIf cfg.isEdge {
      mode = "0440";
      owner = config.services.redis.servers."caddy-storage".user;
      sopsFile = ../secrets/${hostName}/redis.yaml;
    };
    sops.secrets."redis/caddy-client" = {
      mode = "0440";
      owner = config.services.caddy.user;
      sopsFile = ../secrets/${hostName}/redis.yaml;
    };

    services.redis.servers."caddy-storage" = lib.mkIf cfg.isEdge {
      enable = true;
      port = 7000;
      bind = "127.0.0.1 ${edgeNebulaIP}";
      requirePassFile = config.sops.secrets."redis/caddy-server".path;
    };
    systemd.services."redis-caddy-storage" = lib.mkIf cfg.isEdge {
      after = [ "nebula@serverNetwork.service" ];
      before = [ "caddy.service" ];
    };

    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/pberkel/caddy-storage-redis@v1.4.0" ];
        hash = "sha256-TkylmwkyUT1gHKGQukNIsfrlfZDA35gkbhAs2X4Bp5g=";
      };
      dataDir = "/persist/caddy";
      logDir = "/persist/caddy-log";
      email = "admin@partanengroup.de";
      globalConfig = ''
        storage redis {
          host ${if cfg.isEdge then "127.0.0.1" else edgeNebulaIP}
          port 7000
          password "{$REDIS_PASSWORD}"
        }
        metrics /metrics
      '';
      logFormat = ''
        output file ${config.services.caddy.logDir}/caddy_main.log {
          mode 0770
          roll_size 100MiB
          roll_keep 5
          roll_keep_for 100d
        }
        format json
        level INFO
      '';
      virtualHosts = lib.mkMerge (lib.mapAttrsToList (domain: domCfg: let
        forwardURL = if (cfg.isEdge && (domCfg.destIPedge != null))
          then "http://${domCfg.destIPedge}:${builtins.toString domCfg.destPort}"
          else "http://${domCfg.destIP}:${builtins.toString domCfg.destPort}";
        sharedConfig = ''
          #configure hsts
          header Strict-Transport-Security "max-age=31536000; includeSubdomains; preload"
          #compression
          encode zstd gzip
        '';
        logFormatPerHost = ''
          output file ${config.services.caddy.logDir}/${domain}.log {
            mode 0770
            roll_size 100MiB
            roll_keep 5
            roll_keep_for 100d
          }
          format json
          level INFO
        '';
      in {
        "${domain}" = {
          logFormat = logFormatPerHost;
          extraConfig = sharedConfig + domCfg.additionalConfig + ''
            #reverse proxy
            reverse_proxy ${forwardURL}
          '';
        };
        "www.${domain}" = {
          logFormat = logFormatPerHost;
          extraConfig = sharedConfig + ''
            #redirect www domains
            redir https://${domain}{uri}
          '';
        };
      }) cfg.proxies);
    };
    systemd.tmpfiles.settings."10-caddy" = {
      "/persist/caddy"."d" = {
        user = config.services.caddy.user;
        group = config.services.caddy.group;
        mode = "0700";
      };
      "/persist/caddy-log"."d" = {
        user = config.services.caddy.user;
        group = config.services.caddy.group;
        mode = "0770";
      };
    };
    systemd.services.caddy = {
      serviceConfig.EnvironmentFile = config.sops.secrets."redis/caddy-client".path;
      environment.CADDY_ADMIN = lib.mkIf (hostName != "mainserver") "${hostNebulaIP}:2019";
    };

    #scrape configs with promtail
    services.promtail.configuration.scrape_configs = [{
      job_name = "caddy";
      static_configs = [{
        targets = [ "localhost" ];
        labels = {
          job = "caddy";
          host = hostName;
          __path__ = "/persist/caddy-log/*";
          agent = "caddy-promtail";
        };
      }];
      pipeline_stages = [
        {
          json.expressions = {
            duration = "duration";
            status = "status";
          };
        }
        {
          labels = {
            duration = "";
            status = "";
          };
        }
      ];
    }];
    users.users.promtail.extraGroups = lib.mkIf config.services.promtail.enable [ config.services.caddy.group ];

    #Firewall stuff
    networking.firewall.allowedTCPPorts = [ 80 443 7000 2019 ];
    services.nebula.networks."serverNetwork" = {
      firewall.inbound = (lib.optional cfg.isEdge {
          port = 7000;
          proto = "tcp";
          group = "edge";
        }) ++ lib.optional (hostName != "mainserver") { #open up caddy telemetry to mainserver
          port = 2019;
          proto = "tcp";
          host = config.myModules.nebula."serverNetwork".ipMap.mainserver;
      };
    };

    services.unbound.settings.server = lib.mkIf cfg.localDNS.enable {
      local-zone = builtins.concatLists (lib.mapAttrsToList (domain: _: 
        [
          "\"${domain}\" transparent"
          "\"www.${domain}\" transparent"
        ]
      ) cfg.proxies);
      local-data = builtins.concatLists (lib.mapAttrsToList (domain: _:
        [
          "\"${domain} 3600 IN A ${cfg.localDNS.localForwardIP}\""
          "\"www.${domain} 3600 IN A ${cfg.localDNS.localForwardIP}\""
        ]
      ) cfg.proxies);
    };
  };
}
