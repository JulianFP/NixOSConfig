{ config, pkgs, lib, hostName, ...}:
# this config is mostly from: https://kevincox.ca/2022/12/09/valheim-server-nixos-v2/
# thank you!
let
	# Set to {id}-{branch}-{password} for betas.
	steam-app = "896660";
in
{
  imports = [
		./steam.nix
	];

	users.users.valheim = {
		isSystemUser = true;
		# Valheim puts save data in the home directory.
		home = "/var/lib/valheim";
		createHome = true;
		homeMode = "750";
		group = "valheim";
	};
	users.groups.valheim = {};

  #define valheim server startup script and config options here
  #refer to step 3 under section "Running the Dedicated Server" of the "Valheim Dedicated Server Manual.pdf" under /var/lib/steam-app-896660/
  sops.secrets."serverPassword".sopsFile = ../secrets/${hostName}/valheim.yaml;
  sops.templates."start_server.sh" = {
    content = lib.escapeShellArgs [
      "/var/lib/steam-app-${steam-app}/valheim_server.x86_64"
      "-nographics" #not documented, does it do anything?
      "-batchmode" #not documented, does it do anything?
      "-name" "Fulcrum"
      "-port" "2456"
      "-world" "Dedicated"
      "-password" "${config.sops.placeholder.serverPassword}"
      "-savedir" "/var/lib/valheim/save"
      "-public" "1"
      "-logFile" "/var/lib/valheim/log" # if enabled then log will not appear in journal
      "-saveinterval" "600" #saves every 10 minutes automatically
      "-backups" "0" # I take my own backups, if you don't you can remove this to use the built-in basic rotation system.
      # "-crossplay" # This is broken because it looks for "party" shared library in the wrong path.
    ];
    owner = "valheim";
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
			User = "valheim";
			WorkingDirectory = "~";
		};
		environment = {
			# linux64 directory is required by Valheim.
      LD_LIBRARY_PATH = "/var/lib/steam-app-${steam-app}/linux64:${pkgs.zlib}/lib:${pkgs.glibc}/lib";
			SteamAppId = "892970";
		};
	};
}
