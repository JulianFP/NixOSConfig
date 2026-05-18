{ pkgs, ... }:

{
  wayland.windowManager.hyprland.settings = {
    monitor = [
      # Samsung C27HG7x
      #"desc:Samsung Electric Company C27HG7x HTHK300334, 2560x1440@144, 0x0, 1"
      # Iiyama PL2280H
      #"HDMI-A-1, 1920x1080@60, 2560x0, 1"
      "desc:Samsung Electric Company LS32A70 HNMR400480, 3840x2160@60, -1920x0, 2"
      "desc:Samsung Electric Company Odyssey G70B H1AK500000, 3840x2160@120, 0x0, 1.5"
      "HDMI-A-1, 1920x1080@60, 2560x0, 1"
      # fallback rule for random monitors
      ",preferred,auto,auto"
    ];

    workspace = [
      "1, monitor:desc:Samsung Electric Company Odyssey G70B H1AK500000, default:true"
      "10, monitor:desc:Samsung Electric Company Odyssey G70B H1AK500000"
    ];

    #default/primary monitor
    cursor.default_monitor = "DP-3";
    exec-once = [ "${pkgs.xrandr}/bin/xrandr --output DP-3 --primary" ];

    #input.tablet.output = "desc:Samsung Electric Company C27HG7x HTHK300334";
    input.tablet.output = "desc:Samsung Electric Company Odyssey G70B H1AK500000";
  };
}
