{ pkgs, ... }:

{
  wayland.windowManager.hyprland.settings = {
    monitor = [
      {
        output = "desc:Samsung Electric Company C27HG7x HTHK300334";
        mode = "2560x1440@144";
        position = "0x0";
        scale = 1;
      }
      {
        # Iiyama PL2280H
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
        monitor = "desc:Samsung Electric Company C27HG7x HTHK300334";
        default = true;
      }
      {
        workspace = "10";
        monitor = "desc:Samsung Electric Company C27HG7x HTHK300334";
      }
    ];

    config = {
      #default/primary monitor
      cursor.default_monitor = "DP-3";

      input.tablet.output = "desc:Samsung Electric Company C27HG7x HTHK300334";
    };
    exec_cmd = [ "${pkgs.xrandr}/bin/xrandr --output DP-3 --primary" ];
  };
}
