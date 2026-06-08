{ pkgs, ... }:

{
  wayland.windowManager.hyprland.settings = {
    monitor = [
      # Samsung C27HG7x
      #"desc:Samsung Electric Company C27HG7x HTHK300334, 2560x1440@144, 0x0, 1"
      # Iiyama PL2280H
      #"HDMI-A-1, 1920x1080@60, 2560x0, 1"
      {
        output = "desc:Samsung Electric Company LS32A70 HNMR400480";
        mode = "3840x2160@60";
        position = "-1920x0";
        scale = 2;
      }
      {
        output = "desc:Samsung Electric Company Odyssey G70B H1AK500000";
        mode = "3840x2160@120";
        position = "0x0";
        scale = 1.5;
      }
      {
        output = "HDMI-A-1";
        mode = "1920x1080@60";
        position = "2560x0";
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

    workspace_rule = [
      {
        workspace = "1";
        monitor = "desc:Samsung Electric Company Odyssey G70B H1AK500000";
        default = true;
      }
      {
        workspace = "10";
        monitor = "desc:Samsung Electric Company Odyssey G70B H1AK500000";
      }
    ];

    config = {
      #default/primary monitor
      cursor.default_monitor = "DP-3";

      #input.tablet.output = "desc:Samsung Electric Company C27HG7x HTHK300334";
      input.tablet.output = "desc:Samsung Electric Company Odyssey G70B H1AK500000";
    };
    exec_cmd = [ "${pkgs.xrandr}/bin/xrandr --output DP-3 --primary" ];
  };
}
