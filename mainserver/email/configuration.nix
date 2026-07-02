{
  config,
  pkgs,
  inputs,
  hostName,
  ...
}:

let
  mail_domain = "mail.partanengroup.de";
  rspamd_domain = "rspamd.${mail_domain}";
in
{
  imports = [
    inputs.simple-nixos-mailserver.nixosModule
  ];

  #ACME with DNS challenge
  sops.secrets."ionos".sopsFile = ../../secrets/${hostName}/email.yaml;
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "admin@partanengroup.de";
      dnsProvider = "ionos";
      environmentFile = config.sops.secrets."ionos".path;
      extraLegoFlags = [
        "--dns.resolvers=1.1.1.1:53,8.8.8.8:53"
      ];
      group = config.services.nginx.group;
    };
    certs = {
      ${mail_domain} = { };
      ${rspamd_domain} = { };
    };
  };

  sops.secrets."ldap_token" = {
    sopsFile = ../../secrets/${hostName}/ldap.yaml;
    owner = config.services.postfix.user;
    group = config.services.dovecot2.settings.default_internal_group;
  };
  mailserver = {
    enable = true;
    stateVersion = 4;
    fqdn = mail_domain;
    domains = [ "partanengroup.de" ];

    storage.path = "/persist/backMeUp/vmail";
    dkim.keyDirectory = "/persist/backMeUp/dkim";

    virusScanning = true;

    x509.useACMEHost = mail_domain;

    ldap = {
      enable = true;
      uris = [ "ldaps://account.partanengroup.de:3636" ];
      bind = {
        dn = "dn=token";
        passwordFile = config.sops.secrets."ldap_token".path;
      };
      dovecot = {
        userFilter =
          with config.mailserver.ldap.attributes;
          "(&(class=account)(memberof=spn=mail-server@account.partanengroup.de)(${mail}=%{user}))";
        passFilter = config.mailserver.ldap.dovecot.userFilter;
      };
      postfix.filter =
        with config.mailserver.ldap.attributes;
        "(&(class=account)(memberof=spn=mail-server@account.partanengroup.de)(${mail}=%s))";
      base = "dc=account,dc=partanengroup,dc=de";
      scope = "sub";
      attributes = {
        username = "mail";
        mail = "mail";
        password = null;
        uuid = "uuid";
      };
    };

    #full text search
    fullTextSearch = {
      enable = true;
      autoIndex = true;
      memoryLimit = 2000;
      fallback = true;
    };

    rejectRecipients = [
      "noreply@partanengroup.de"
    ];
    forwards = {
      "postmaster@partanengroup.de" = "julian@partanengroup.de";
      "abuse@partanengroup.de" = "julian@partanengroup.de";
      "admin@partanengroup.de" = "julian@partanengroup.de";
      "maro@partanengroup.de" = [
        "marvin@partanengroup.de"
        "robin@partanengroup.de"
      ];
    };
  };

  #disable mail rejection
  services.rspamd.extraConfig = ''
    actions {
      reject = null; # Disable rejects, default is 15
      add_header = 6; # Add header when reaching this score
      greylist = 4; # Apply greylisting when reaching this score
    }
  '';

  #webmail
  services.roundcube = {
    enable = true;
    hostName = mail_domain;
    dicts = with pkgs.aspellDicts; [
      en
      de
    ];
    extraConfig = ''
      $config['imap_host'] = 'ssl://${mail_domain}:993';
      $config['username_domain'] = [
        '${mail_domain}' => 'partanengroup.de',
      ];
      $config['smtp_host'] = 'ssl://%h:465';
      $config['smtp_user'] = '%u';
      $config['smtp_pass'] = '%p';
    '';
  };
  services.postgresqlBackup = {
    enable = true;
    startAt = "*-*-* 02:00:00";
    compression = "zstd";
    location = "/persist/backMeUp/roundcube/postgresqlBackup";
  };

  #access to rspamd web interface
  sops.secrets."rspamd_ui" = {
    sopsFile = ../../secrets/${hostName}/rspamd.yaml;
    owner = "nginx";
  };
  services.nginx = {
    enable = true;
    virtualHosts = {
      ${mail_domain} = {
        # roundcube nginx overwrite
        enableACME = false;
        acmeRoot = null; # DNS challenge
        useACMEHost = mail_domain;
      };
      ${rspamd_domain} = {
        forceSSL = true;
        useACMEHost = rspamd_domain;
        acmeRoot = null;
        basicAuthFile = config.sops.secrets."rspamd_ui".path;
        serverName = rspamd_domain;
        locations = {
          "/" = {
            proxyPass = "http://unix:/run/rspamd/worker-controller.sock:/";
          };
        };
      };
    };
  };
}
