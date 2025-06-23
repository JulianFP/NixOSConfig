{ pkgs, ... }:

{
  xdg = {
    configFile = {
      "autostart/stylix-activate-kde.desktop".enable = false;
      "autostart/stylix-activate-gnome.desktop".enable = false;
    };

    desktopEntries =
      let
        makeIamb = profileName: {
          name = "iamb ${profileName}";
          genericName = "Matrix client - ${profileName} profile";
          exec = "iamb -P ${profileName}";
          terminal = true;
          type = "Application";
          comment = "Matrix client for Vim addicts - ${profileName} profile";
          categories = [
            "Network"
            "InstantMessaging"
            "Chat"
          ];
          settings.StartupWMClass = "iamb - ${profileName}";
        };
      in
      {
        signal-desktop = {
          # start signal in system tray and with more languages supported for spell checker
          name = "Signal";
          exec = "env LANGUAGE=\"en-US:de-DE\" signal-desktop --start-in-tray %U";
          terminal = false;
          type = "Application";
          icon = "signal-desktop";
          comment = "Private messaging from your desktop";
          mimeType = [
            "x-scheme-handler/sgnl"
            "x-scheme-handler/signalcaptcha"
          ];
          categories = [
            "Network"
            "InstantMessaging"
            "Chat"
          ];
          settings.StartupWMClass = "signal";
        };
        discord = {
          # start discord in system tray
          name = "Discord";
          exec = "Discord --start-minimized";
          type = "Application";
          icon = "discord";
          categories = [
            "Network"
            "InstantMessaging"
          ];
          genericName = "All-in-one cross-platform voice and text chat for gamers";
          mimeType = [
            "x-scheme-handler/discord"
          ];
          settings = {
            StartupWMClass = "discord";
            Version = "1.4";
          };
        };
        iamb-private = makeIamb "private";
        iamb-uni = makeIamb "uni";
      };
    autostart = {
      enable = true;
      readOnly = true;
      entries = [
        "/etc/profiles/per-user/julian/share/applications/signal-desktop.desktop"
        "/etc/profiles/per-user/julian/share/applications/discord.desktop"
        "${pkgs.keepassxc}/share/applications/org.keepassxc.KeePassXC.desktop"
        "${pkgs.thunderbird}/share/applications/thunderbird.desktop"
        "${pkgs.nextcloud-client}/share/applications/com.nextcloud.desktopclient.nextcloud.desktop"
      ];
    };
  };
}
