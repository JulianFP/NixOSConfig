{ ...}:

{
  wayland.windowManager.hyprland.settings = {
    monitor = [
      # Samsung C27HG7x
      "desc:Samsung Electric Company C27HG7x HTHK300334, 2560x1440@144, 0x0, 1"
      # Iiyama PL2280H
      "HDMI-A-1, 1920x1080@60, 2560x0, 1"
      # fallback rule for random monitors
      ",preferred,auto,auto"
    ];

    input.tablet.output = "desc:Samsung Electric Company C27HG7x HTHK300334";
  };
}
