{ ... }:

let
  username = "julian";
in
{
  # USB-serial latency timer for TRLC-DK1
  services.udev.extraRules = ''
    # Set USB-serial latency timer to 1 ms
    ACTION=="add", SUBSYSTEM=="usb-serial", KERNEL=="ttyUSB[0-9]*", ATTR{latency_timer}="1"
  '';

  # Real-time scheduling privileges
  security.pam.loginLimits = [
    {
      domain = username;
      type = "-";
      item = "rtprio";
      value = "50";
    }
    {
      domain = username;
      type = "-";
      item = "memlock";
      value = "unlimited";
    }
  ];
}
