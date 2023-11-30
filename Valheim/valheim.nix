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

  sops.secrets."serverPassword" = {
    owner = "valheim";
    sopsFile = ../secrets/${hostName}/valheim.yaml;
  };

	users.users.valheim = {
		isSystemUser = true;
		# Valheim puts save data in the home directory.
		home = "/var/lib/valheim";
		createHome = true;
		homeMode = "750";
		group = "valheim";
	};

	users.groups.valheim = {};

	systemd.services.valheim = {
		wantedBy = [ "multi-user.target" ];

		# Install the game before launching.
		wants = [ "steam@${steam-app}.service" ];
		after = [ "steam@${steam-app}.service" ];

		serviceConfig = {
			ExecStart = lib.escapeShellArgs [
				"/var/lib/steam-app-${steam-app}/valheim_server.x86_64"
				"-nographics"
				"-batchmode"
				# "-crossplay" # This is broken because it looks for "party" shared library in the wrong path.
				"-savedir" "/var/lib/valheim/save"
				"-name" "Fulcrum"
				"-port" "2456"
				"-world" "Dedicated"
				"-password" "$(cat ${config.sops.secrets."serverPassword".path})"
				"-public" "1"
				"-backups" "0" # I take my own backups, if you don't you can remove this to use the built-in basic rotation system.
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
