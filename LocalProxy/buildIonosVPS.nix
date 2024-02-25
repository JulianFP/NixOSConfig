{ lib, config, pkgs, ... }:

{
  systemd.services.nixos-upgrade-IonosVPS = {
    description = "Remote NixOS Upgrade of IonosVPS machine";

    restartIfChanged = false;
    unitConfig.X-StopOnRemoval = false;

    serviceConfig.Type = "oneshot";

    environment = config.nix.envVars // {
      inherit (config.environment.sessionVariables) NIX_PATH;
      HOME = "/root";
    } // config.networking.proxy.envVars;

    path = with pkgs; [
      coreutils
      gnutar
      xz.bin
      gzip
      gitMinimal
      config.nix.package.out
      config.programs.ssh.package
      openssh
    ];

    #allowReboot is activated
    script = let
      date     = "${pkgs.coreutils}/bin/date";
      readlink = "${pkgs.coreutils}/bin/readlink";
      ssh = command: lib.escapeShellArgs [
        "${pkgs.openssh}/bin/ssh"
        "IonosVPS"
        command
      ];
      nixos-rebuild = operation: lib.escapeShellArgs [
        "${config.system.build.nixos-rebuild}/bin/nixos-rebuild"
        operation
        "--flake"
        (config.system.autoUpgrade.flake + "#IonosVPS")
        "--target-host"
        "IonosVPS"
      ];
    in if config.system.autoUpgrade.allowReboot then ''
      ${nixos-rebuild "boot"}
      booted="$(${ssh "readlink /run/booted-system/{initrd,kernel,kernel-modules}"})"
      built="$(${ssh "readlink /nix/var/nix/profiles/system/{initrd,kernel,kernel-modules}"})"

      ${lib.optionalString (config.system.autoUpgrade.rebootWindow != null) ''
        current_time="$(${date} +%H:%M)"

        lower="${config.system.autoUpgrade.rebootWindow.lower}"
        upper="${config.system.autoUpgrade.rebootWindow.upper}"

        if [[ "''${lower}" < "''${upper}" ]]; then
          if [[ "''${current_time}" > "''${lower}" ]] && \
              [[ "''${current_time}" < "''${upper}" ]]; then
            do_reboot="true"
          else
            do_reboot="false"
          fi
        else
          # lower > upper, so we are crossing midnight (e.g. lower=23h, upper=6h)
          # we want to reboot if cur > 23h or cur < 6h
          if [[ "''${current_time}" < "''${upper}" ]] || \
              [[ "''${current_time}" > "''${lower}" ]]; then
            do_reboot="true"
          else
            do_reboot="false"
          fi
        fi
      ''}

      if [ "''${booted}" = "''${built}" ]; then
        ${nixos-rebuild config.system.autoUpgrade.operation}
      ${lib.optionalString (config.system.autoUpgrade.rebootWindow != null) ''
        elif [ "''${do_reboot}" != true ]; then
          echo "Outside of configured reboot window, skipping."
      ''}
      else
        ${ssh "shutdown -r +1"}
      fi
    '' else ''
      ${nixos-rebuild config.system.autoUpgrade.operation}
    '';

    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    
    #start this with/before nixos-upgrade of this system
    before = [ "nixos-upgrade.service" ];
    wantedBy = [ "nixos-upgrade.service" ];
  };
}
