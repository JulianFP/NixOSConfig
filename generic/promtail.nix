{ hostName, ... }:

{
  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 9080;
        grpc_listen_port = 0;
        log_level = "warn";
      };
      positions.filename = "/persist/promtail/positions.yaml";
      clients = [
        {
          url = "http://48.42.0.2:3100/loki/api/v1/push";
        }
      ];
      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = hostName;
            };
          };
          relabel_configs = [
            {
              source_labels = [ "__journal__systemd_unit" ];
              target_label = "unit";
            }
          ];
        }
      ];
    };
  };
  systemd.tmpfiles.settings."10-promtail"."/persist/promtail"."d" = {
    user = "promtail";
    group = "promtail";
    mode = "0700";
  };
}
