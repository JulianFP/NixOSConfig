{
  config,
  lib,
  hostName,
  pkgs,
  ...
}:

let
  cfg = config.myModules.fluent-bit;
in
{
  options.myModules.fluent-bit = {
    host = lib.mkOption {
      type = lib.types.str;
      default = config.myModules.nebula."serverNetwork".ipMap.mainserver;
    };
  };

  config = {
    services.fluent-bit = {
      enable = true;
      settings = {
        pipeline = {
          inputs = [
            {
              name = "systemd";
              systemd_filter = "_SYSTEMD_UNIT=fluent-bit.service";
              db = "/var/lib/private/fluent-bit/systemd.db";
              tag = "journal";
            }
          ];

          filters = [
            {
              name = "modify";
              match = "journal";

              # static labels
              add = [
                "job systemd-journal"
                "host ${hostName}"
              ];
            }
            {
              name = "modify";
              match = "journal";

              # _SYSTEMD_UNIT -> unit
              rename = "_SYSTEMD_UNIT unit";
            }
          ];

          outputs = [
            {
              name = "loki";
              match = "journal";
              host = cfg.host;
              labels = "job=$job,host=$host,unit=$unit";
            }
          ];
        };
      };
    };

    systemd.services.fluent-bit = {
      after = [ "nebula@serverNetwork.service" ];
      serviceConfig = {
        StateDirectory = "fluent-bit";
        ExecStartPre = pkgs.writeShellScript "wait-for-loki" ''
          until ${pkgs.curl}/bin/curl -sf http://${cfg.host}:3100/ready >/dev/null; do
            sleep 1
          done
        '';
      };
    };
    environment.persistence."/persist".directories = [ "/var/lib/private/fluent-bit" ];
  };
}
