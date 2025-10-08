{
  config,
  inputs,
  hostName,
  trustedProxyIP,
  ...
}:
{
  imports = [
    inputs.project-W.nixosModules.default
  ];

  networking.hosts = {
    #to access Kanidm using it's domain over local container ip
    "10.42.42.137" = [ "account.partanengroup.de" ];
  };

  sops.secrets = {
    "project-w_secrets".sopsFile = ../../secrets/${hostName}/project-w.yaml;
    "project-w-runner_secrets" = {
      mode = "0400";
      owner = config.services.project-W.runner.user;
      sopsFile = ../../secrets/${hostName}/project-w.yaml;
    };
    "project-w_service".sopsFile = ../../secrets/Kanidm/${hostName}_client-secret.yaml;
  };
  sops.templates."project-w_final-env-file" = {
    content = ''
      ${config.sops.placeholder."project-w_secrets"}
      OIDC_CLIENT_SECRET=${config.sops.placeholder."project-w_service"}
    '';
    mode = "0400";
    owner = config.services.project-W.server.user;
  };

  services = {
    project-W = {
      server = {
        enable = true;
        settings = {
          client_url = "https://project-w.partanengroup.de/#";
          web_server = {
            allowed_hosts = [
              "project-w.partanengroup.de"
              "localhost"
            ];
            reverse_proxy.trusted_proxies = [
              "10.42.42.1"
              trustedProxyIP
            ];
            no_https = true;
          };
          security = {
            secret_key = "!ENV \${SECRET_KEY}";
            local_account.mode = "disabled";
            oidc_providers."PartanenGroup Account" = {
              base_url = "https://account.partanengroup.de/oauth2/openid/project-w_service";
              icon_url = "https://kanidm.com/images/logo.svg";
              client_id = "project-w_service";
              client_secret = "!ENV \${OIDC_CLIENT_SECRET}";
              user_role = {
                field_name = "role";
                name = "user";
              };
              admin_role = {
                field_name = "role";
                name = "admin";
              };
            };
          };
          smtp_server = {
            hostname = "mail.partanengroup.de";
            port = 587;
            secure = "starttls";
            sender_email = "noreply@partanengroup.de";
            username = "noreply@partanengroup.de";
            password = "!ENV \${SMTP_PASSWORD}";
          };
        };
        envFile = config.sops.templates."project-w_final-env-file".path;
      };

      runner = {
        enable = true;
        settings = {
          runner_attributes.name = "mainserver runner 01";
          backend_settings = {
            url = "http://localhost:5000";
            auth_token = "!ENV \${AUTH_TOKEN}";
          };
          whisper_settings = {
            model_prefetching = "without_alignment";
            hf_token = "!ENV \${HF_TOKEN}";
            torch_device = "cpu";
            compute_type = "int8";
            batch_size = 4;
          };
        };
        envFile = config.sops.secrets."project-w-runner_secrets".path;
      };
    };

    postgresqlBackup = {
      enable = true;
      startAt = "*-*-* 02:00:00";
      compression = "zstd";
      location = "/persist/backMeUp/postgresqlBackup";
    };
  };
}
