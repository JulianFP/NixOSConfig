{
  config,
  pkgs,
  lib,
  hostName,
  ...
}:
# this config is inspired from: https://kevincox.ca/2022/12/09/valheim-server-nixos-v2/
# thank you!
# please note that the host enabling this module needs to have a sops valheim.yaml secret file containing the server access password set up!
let
  # Set to {id}-{branch}-{password} for betas.
  steam-app = "896660";
  cfg = config.myModules.valheim;
in
{
  options = {
    myModules.valheim = {
      enable = lib.mkEnableOption ("Valheim dedicated server");
      port = lib.mkOption {
        type = lib.types.port;
        default = 2456;
        description = ''
          First Valheim Port. Valheim will use this port and the port after it (default: port range 2456-2457).
        '';
      };
      serverName = lib.mkOption {
        type = lib.types.singleLineStr;
        description = ''
          The name of this server how it will be shown to users in the server list.
        '';
      };
      steamUser = lib.mkOption {
        type = lib.types.singleLineStr;
        default = "steam";
        description = ''
          User that will be created for the steam service.
        '';
      };
      valheimUser = lib.mkOption {
        type = lib.types.singleLineStr;
        default = "valheim";
        description = ''
          User that will be created for the valheim service.
        '';
      };
      group = lib.mkOption {
        type = lib.types.singleLineStr;
        default = "steam";
        description = ''
          Shared group that will be created for the valheim and steam services.
        '';
      };
      steamPersistDir = lib.mkOption {
        type = lib.types.singleLineStr;
        default = "/var/lib/steam";
        description = ''
          A persistent directory where steam, the game package and other binaries will be unpacked to. Doesn't need to be backed up.
        '';
      };
      dataDir = lib.mkOption {
        type = lib.types.singleLineStr;
        default = "/persist/backMeUp/valheim";
        description = ''
          A persistent directory where the game data will be saved to. You may want to backup this directory.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    #setup steam
    users = {
      users."${cfg.steamUser}" = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.steamPersistDir;
        homeMode = "750";
        createHome = true;
      };
      groups."${cfg.group}" = { };
    };

    systemd.services."steam@" = {
      unitConfig = {
        StopWhenUnneeded = true;
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${
          pkgs.resholve.writeScript "steam"
            {
              interpreter = "${pkgs.zsh}/bin/zsh";
              inputs = with pkgs; [
                patchelf
                steamcmd
              ];
              execer = with pkgs; [
                "cannot:${steamcmd}/bin/steamcmd"
              ];
            }
            ''
              set -eux

              instance=''${1:?Instance Missing}
              eval 'args=(''${(@s:_:)instance})'
              app=''${args[1]:?App ID missing}
              beta=''${args[2]:-}
              betapass=''${args[3]:-}

              dir=${cfg.steamPersistDir}/steam-app-$instance

              cmds=(
                +force_install_dir $dir
                +login anonymous
                +app_update $app validate
              )

              if [[ $beta ]]; then
                cmds+=(-beta $beta)
                if [[ $betapass ]]; then
                  cmds+=(-betapassword $betapass)
                fi
              fi

              cmds+=(+quit)

              steamcmd $cmds

              for f in $dir/*; do
                if ! [[ -f $f && -x $f ]]; then
                  continue
                fi

                # Update the interpreter to the path on NixOS.
                patchelf --set-interpreter ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 $f || true
              done
            ''
        } %i";
        PrivateTmp = true;
        Restart = "on-failure";
        StateDirectory = "steam-app-%i";
        TimeoutStartSec = 3600; # Allow time for updates.
        User = cfg.steamUser;
        Group = cfg.group;
        WorkingDirectory = "~";
      };
    };

    #setup valheim
    users.users."${cfg.valheimUser}" = {
      isSystemUser = true;
      # Valheim puts save data in the home directory.
      home = cfg.dataDir;
      createHome = true;
      group = cfg.group;
    };

    #define valheim server startup script and config options here
    #refer to step 3 under section "Running the Dedicated Server" of the "Valheim Dedicated Server Manual.pdf" under ${cfg.steamPersistDir}/steam-app-896660/
    sops.secrets."serverPassword".sopsFile = ../secrets/${hostName}/valheim.yaml;
    sops.templates."start_server.sh" = {
      content = lib.escapeShellArgs [
        "${cfg.steamPersistDir}/steam-app-${steam-app}/valheim_server.x86_64"
        "-nographics" # not documented, does it do anything?
        "-batchmode" # not documented, does it do anything?
        "-name"
        cfg.serverName
        "-port"
        cfg.port
        "-world"
        cfg.serverName
        "-password"
        "${config.sops.placeholder.serverPassword}"
        "-savedir"
        "${cfg.dataDir}/save"
        "-public"
        "1"
        #"-logFile" "${persistDir}/log" # if enabled then log will not appear in journal
        "-saveinterval"
        "600" # saves every 10 minutes automatically
        "-backups"
        "0" # I take my own backups, if you don't you can remove this to use the built-in basic rotation system.
        # "-crossplay" # This is broken because it looks for "party" shared library in the wrong path.
      ];
      owner = cfg.valheimUser;
      mode = "0550";
    };

    systemd.services.valheim = {
      wantedBy = [ "multi-user.target" ];

      # Install the game before launching.
      wants = [ "steam@${steam-app}.service" ];
      after = [ "steam@${steam-app}.service" ];

      serviceConfig = {
        ExecStart = lib.escapeShellArgs [
          "${pkgs.bash}/bin/bash"
          "${config.sops.templates."start_server.sh".path}"
        ];
        Nice = "-5";
        PrivateTmp = true;
        Restart = "always";
        User = cfg.valheimUser;
        Group = cfg.group;
        WorkingDirectory = "~";
      };
      environment = {
        # linux64 directory is required by Valheim.
        LD_LIBRARY_PATH = "${cfg.steamPersistDir}/steam-app-${steam-app}/linux64:${pkgs.zlib}/lib:${pkgs.glibc}/lib";
        SteamAppId = "892970";
      };
    };
  };
}
