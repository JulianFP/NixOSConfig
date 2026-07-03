{ pkgs, lib, ... }:

{
  #additional system script for laptop lid
  home.file = {
    "clamshell_mode_hypr.sh" = {
      target = ".systemScripts/clamshell_mode_hypr.sh";
      source = ./systemScripts/clamshell_mode_hypr.sh;
      executable = true;
    };
    "lockAndSuspend.sh".source = ./systemScripts/lockAndSuspend.sh; # this device supports hibernation
  };

  wayland.windowManager.hyprland.settings = {
    monitor = [
      # internal monitor (fractional scaling)
      {
        output = "eDP-1";
        mode = "2256x1504";
        position = "0x0";
        scale = 1.566667;
      }
      # Samsung C27HG7x
      {
        output = "desc:Samsung Electric Company C27HG7x HTHK300334";
        mode = "2560x1440@144";
        position = "1440x0";
        scale = 1;
      }
      # Iiyama PL2280H
      {
        output = "HDMI-A-1";
        mode = "1920x1080@60";
        position = "4000x0";
        scale = 1;
      }
      # fallback rule for random monitors
      {
        output = "";
        mode = "preferred";
        position = "auto";
        scale = "auto";
      }
    ];

    config.input.tablet.output = "eDP-1";

    bind = [
      #framework button
      {
        _args = [
          "XF86AudioMedia"
          (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${pkgs.grimblast}/bin/grimblast --notify --freeze copy area\")")
        ];
      }
      {
        _args = [
          "SUPER + XF86AudioMedia"
          (lib.generators.mkLuaInline "hl.dsp.exec_cmd('${pkgs.grimblast}/bin/grimblast --notify --freeze copysave area \"$screenshotDir/$(date +\"%Y%m%d_%T\")-Screenshot-area.png\"')")
        ];
      }
    ];
  };

  programs.hyprlock.settings.auth.fingerprint.enabled = true;
}
