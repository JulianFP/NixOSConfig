{
  config,
  lib,
  pkgs,
  hostName,
  ...
}:

let
  hostNebulaIP = config.myModules.nebula."serverNetwork".ipMap."${hostName}";
in
{
  services.prometheus = {
    enable = true;
    listenAddress = "localhost";

    #set scrape_interval to be the same for most jobs for grafana. See https://grafana.com/blog/2020/09/28/new-in-grafana-7.2-__rate_interval-for-prometheus-rate-queries-that-just-work/
    globalConfig = {
      scrape_interval = "10s";
      scrape_timeout = "5s";
    };

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = [
              "localhost:${toString config.services.prometheus.exporters.node.port}"
              "${config.myModules.nebula."serverNetwork".ipMap.IonosVPS}:9100"
            ];
          }
        ];
      }
      {
        job_name = "cadvisor";
        static_configs = [
          {
            targets = [ "localhost:${toString config.services.cadvisor.port}" ];
          }
        ];
      }
      {
        #configured in ./unbound.nix
        job_name = "unbound";
        static_configs = [
          {
            targets = [ "localhost:9167" ];
          }
        ];
        scrape_interval = "5m";
      }
      {
        job_name = "caddy";
        static_configs = [
          {
            targets = [
              "localhost:2019"
              "${config.myModules.nebula."serverNetwork".ipMap.IonosVPS}:2019"
            ];
          }
        ];
      }
    ];
  };

  #cadvisor is often used for docker/kubernetes, but since systemd puts services in cgroups too this works with systemd as well
  services.cadvisor = {
    enable = true;
    listenAddress = "localhost";
  };

  #loki and promtail for log aggregation
  services.loki = {
    enable = true;
    dataDir = "/persist/loki";
    configuration = {
      auth_enabled = false;
      server = {
        http_listen_address = hostNebulaIP;
        http_listen_port = 3100;
        grpc_listen_port = 9096;
        log_level = "warn";
        http_server_read_timeout = "60s";
        http_server_write_timeout = "60s";
        http_server_idle_timeout = "3m";
        grpc_server_max_recv_msg_size = 20971520;
        grpc_server_max_send_msg_size = 20971520;
      };
      common = {
        instance_addr = hostNebulaIP;
        path_prefix = "/persist/loki";
        storage.filesystem = {
          chunks_directory = "/persist/loki/chunks";
          rules_directory = "/persist/loki/rules";
        };
        replication_factor = 1;
        ring = {
          kvstore.store = "inmemory";
          instance_addr = hostNebulaIP;
        };
      };
      query_range.results_cache.cache.embedded_cache = {
        enabled = true;
        max_size_mb = 100;
      };
      chunk_store_config.chunk_cache_config.embedded_cache.enabled = false;
      limits_config = {
        discover_log_levels = false; # needed for unbound
        max_query_series = 100000;
        max_entries_limit_per_query = 100000;
        query_timeout = "3m";
        split_queries_by_interval = 0;
      };
      schema_config.configs = [
        {
          from = "2020-10-24";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];
      analytics.reporting_enabled = false;
      frontend = {
        encoding = "protobuf";
        max_outstanding_per_tenant = 2048;
      };
    };
  };

  #grafana for nice dashboards
  sops.secrets."grafana/admin" = {
    mode = "0440";
    owner = "grafana";
    sopsFile = ../secrets/${hostName}/grafana.yaml;
  };
  services.grafana = {
    enable = true;
    dataDir = "/persist/grafana";
    settings = {
      server = {
        http_addr = "${hostNebulaIP}";
        enable_gzip = true;
      };
      security = {
        admin_email = "admin@partanengroup.de";
        admin_password = "$__file{${config.sops.secrets."grafana/admin".path}}";
      };
    };
    provision = {
      enable = true;

      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          uid = "PBFA97CFB590B2093"; # this is referenced in some of my dashboards, so I make it declarative
          url = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
          jsonData.timeInterval = config.services.prometheus.globalConfig.scrape_interval;
        }
        {
          name = "Loki";
          type = "loki";
          uid = "P8E80F9AEF21F6940"; # this is referenced in some of my dashboards, so I make it declarative
          url = "http://${hostNebulaIP}:3100";
        }
      ];

      dashboards.settings.providers = [
        {
          name = "My declarative dashboards";
          options.path = "/etc/grafana-dashboards";
        }
      ];
    };
  };

  #define grafana dashboards (obtained from https://grafana.com/grafana/dashboards)
  environment.etc =
    let
      dashboard-builder =
        src:
        pkgs.stdenv.mkDerivation {
          name = "unbound-dashboard";
          src = src;
          phases = [ "installPhase" ];
          installPhase = ''
            ${pkgs.gnused}/bin/sed -e 's/\''${DS_PROMETHEUS-INDUMIA}/PBFA97CFB590B2093/g ; s/\''${DS_PROMETHEUS}/PBFA97CFB590B2093/g ; s/\''${DS_LOKI-INDUMIA}/P8E80F9AEF21F6940/g ; s/\''${DS_LOKI}/P8E80F9AEF21F6940/g' $src > $out
          '';
        };
      grafana-dashboards = {
        "grafana-dashboards/node.json" = pkgs.fetchurl {
          url = "https://grafana.com/api/dashboards/1860/revisions/37/download";
          hash = "sha256-1DE1aaanRHHeCOMWDGdOS1wBXxOF84UXAjJzT5Ek6mM=";
        };
        "grafana-dashboards/cadvisor.json" = ./grafana-dashboards/cadvisor.json;
        "grafana-dashboards/zfs.json" = ./grafana-dashboards/zfs.json;
        "grafana-dashboards/unbound.json" = dashboard-builder (
          pkgs.fetchzip {
            url = "https://github.com/ar51an/unbound-dashboard/releases/download/v2.3/unbound-dashboard-release-2.3.tar.gz";
            hash = "sha256-VBXvDJQXfBBn6SMMU/98Yv8aS0RR4O5NWXzOO/cD35k=";
          }
          + "/unbound-dashboard.json"
        );
        "grafana-dashboards/caddy.json" = dashboard-builder (
          pkgs.fetchurl {
            url = "https://grafana.com/api/dashboards/20802/revisions/1/download";
            hash = "sha256-vSt63PakGp5NzKFjbU5Yh0nDbKET5QRWp5nusM76/O4=";
          }
        );
      };
    in
    lib.mapAttrs (_: value: {
      source = value;
      mode = "0440";
      user = "grafana";
      group = "grafana";
    }) grafana-dashboards;

  environment.persistence."/persist".directories = [
    "/var/lib/${config.services.prometheus.stateDir}"
  ];

  networking.firewall.allowedTCPPorts = [
    config.services.grafana.settings.server.http_port
    3100
  ];
  services.nebula.networks."serverNetwork".firewall.inbound = [
    {
      #open up loki port to all servers so that they can push their logs too
      port = 3100;
      proto = "tcp";
      group = "server";
    }
    {
      port = 3100;
      proto = "tcp";
      group = "edge";
    }
    {
      port = config.services.grafana.settings.server.http_port;
      proto = "tcp";
      group = "client";
    }
  ];
}
