{ config, inputs, ... }:

let
  pkgs-unstable = (import inputs.nixpkgs {
    system = "x86_64-linux";
  });
in
{
  nixpkgs.overlays = [
    (self: super: {
      inherit (pkgs-unstable) home-assistant;
    })
  ];

  disabledModules = [
    "services/home-automation/home-assistant.nix"
  ];

  imports = [
    "${inputs.nixpkgs}/nixos/modules/services/home-automation/home-assistant.nix"
  ];

  services.home-assistant = {
    enable = true;
    configDir = "/persist/backMeUp";

    #use PostgreSQL instead of SQLite for better performance
    extraPackages = ps: with ps; [ psycopg2 ];
    config.recorder.db_url = "postgresql://@/hass";

    extraComponents = [
      # Components required to complete the onboarding
      "analytics"
      "google_translate"
      "met"
      "radio_browser"
      "shopping_list"
      # Recommended for fast zlib compression
      # https://www.home-assistant.io/integrations/isal
      "isal"
      #zigbee
      "zha"
    ];
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = {};

      http = {
        trusted_proxies = [ 
          "10.42.42.1"
          "48.42.0.5"
        ];
        use_x_forwarded_for = true;
      };
    };
  };

  services.postgresql = {
    enable = true;
    dataDir = "/persist/postgresql/${config.services.postgresql.package.psqlSchema}";
    ensureDatabases = [ "hass" ];
    ensureUsers = [{
      name = "hass";
      ensureDBOwnership = true;
    }];
  };
  #impermanence stuff for postgres
  systemd.tmpfiles.settings."10-postgresql"."/persist/postgresql/${config.services.postgresql.package.psqlSchema}"."d" = {
    user = "postgres";
    group = "postgres";
    mode = "0700";
  };
}
