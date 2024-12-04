{ ... }:

{
  #additional system script for laptop lid
  home.file = {
    "clamshell_mode_hypr.sh" = {
      target = ".systemScripts/clamshell_mode_hypr.sh";
      source = ./systemScripts/clamshell_mode_hypr.sh;
      executable = true;
    };
    "lockAndSuspend.sh".source = ./systemScripts/lockAndSuspend.sh; #this device supports hibernation
  };

  wayland.windowManager.hyprland.settings = {
    monitor = [
      # internal monitor (fractional scaling)
      "eDP-1, 2256x1504, 0x0, 1.566667"
      # Samsung C27HG7x
      "desc:Samsung Electric Company C27HG7x HTHK300334, 2560x1440@144, 1440x0, 1"
      # Iiyama PL2280H
      "HDMI-A-1, 1920x1080@60, 4000x0, 1"
      # fallback rule for random monitors
      ",preferred,auto,auto"
    ];

    input = {
      tablet.output = "eDP-1";
    };

    bind = [
      #framework button
      ", XF86AudioMedia, exec, grimblast --notify --freeze copy area"
      "$mainMod, XF86AudioMedia, exec, grimblast --notify --freeze copysave area \"$screenshotDir/$(date +\"%Y%m%d_%T\")-Screenshot-area.png\""
    ];
  };
}
