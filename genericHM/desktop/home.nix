{ config, pkgs, ... }:

{
  imports = [
    ./packages.nix # Packages and Fonts installed for this user
    ./hyprland.nix # Hyprland stu
    ./desktop-entries.nix # custom .desktop files and xdg autostart
    ./mangohud.nix # mangohud config
    ./qt_gtk.nix # qt settings (mainly theming, not handled by stylix yet)
    ./rofi.nix
    ./neovim/neovim.nix
    ./mozilla.nix
  ];

  # direnv
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # additions to git (other stuff defined in genericHM/shell.nix)
  programs.git = {
    signing = {
      format = "openpgp";
      key = "Julian Partanen <julian@partanengroup.de>";
      signByDefault = true;
    };
    ignores = [
      # add direnv stuff to global gitignore
      "*.direnv"
    ];
  };

  # lf
  programs.lf = {
    enable = true;
    commands = {
      #if mimetype is set to nvim: opens file inside current terminal, else: opens file in designated application (new window, asynchronous)
      open = ''
        &{{
          mimetype=$(file --brief --dereference --mime-type $f)
          defapp=$(xdg-mime query default $mimetype)
          case "$defapp" in
          nvim.desktop)
          lf -remote "send $id \$nvim $f"
            ;;
          *)
            xdg-open $f
          esac
        }}
      '';
    };
    extraConfig = ''
      set shell zsh
      set icons true
    '';
    keybindings = {
      # Movement
      "gd" = "cd ~/Documents";
      "gD" = "cd ~/Downloads";
      "gc" = "cd ~/.config";
      "gu" = "cd ~/Nextcloud/Dokumente/Studium";

      # execute current file
      "x" = "\$\$f";
      "X" = "!\$f";

      #open current dir in dolphin
      "<c-a>" = "&{{dolphin --new-window --select \$ &; disown}}";
    };
  };
  xdg.configFile."lf/icons".source = ./lf-icons;

  # set defaultApplications through mime types
  xdg = {
    enable = true;
    systemDirs.data = [
      # add flatpak dirs to path
      "/usr/share:/var/lib/flatpak/exports/share"
      "\$HOME/.local/share/flatpak/exports/share"
    ];
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = config.xdg.userDirs.documents;
    };
    mime.enable = false; # set mime apps manually
    mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = [
          "org.kde.dolphin.desktop"
          "lf.desktop"
        ];
        "application/pdf" = [
          "org.kde.okular.desktop"
          "firefox.desktop"
        ]; # pdf
        "application/x-xz" = [ "org.kde.ark.desktop" ]; # .tar.xz
        "application/gzip" = [ "org.kde.ark.desktop" ]; # .tar.gz
        "application/zip" = [ "org.kde.ark.desktop" ]; # .zip
        "application/vnd.oasis.opendocument.spreadsheet" = [ "calc.desktop" ]; # .ods
        "application/vnd.oasis.opendocument.text" = [ "writer.desktop" ]; # .odt
        "application/vnd.oasis.opendocument.presentation" = [ "impress.desktop" ]; # .odp
        "text/plain" = [ "nvim.desktop" ];
        "text/x-c" = [ "nvim.desktop" ]; # .cpp
        "text/x-file" = [ "nvim.desktop" ]; # .h
        "text/x-shellscript" = [ "nvim.desktop" ]; # .sh
        "text/x-script.python" = [ "nvim.desktop" ]; # .py
        "text/csv" = [
          "calc.desktop"
          "nvim.desktop"
        ]; # .csv, .log
        "video/mp4" = [
          "mpv.desktop"
          "vlc.desktop"
        ]; # .mp4
        "video/webm" = [
          "mpv.desktop"
          "vlc.desktop"
        ]; # .webm
        "image/png" = [ "org.kde.gwenview.desktop" ]; # .png
        "image/jpeg" = [ "org.kde.gwenview.desktop" ]; # .jpg
        "image/webp" = [ "org.kde.gwenview.desktop" ]; # .webp
        "image/gif" = [ "org.kde.gwenview.desktop" ]; # .gif
        #web browser
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
        "x-scheme-handler/chrome" = [ "firefox.desktop" ];
        "text/html" = [ "firefox.desktop" ];
        "application/x-extension-htm" = [ "firefox.desktop" ];
        "application/x-extension-html" = [ "firefox.desktop" ];
        "application/x-extension-shtml" = [ "firefox.desktop" ];
        "application/x-extension-xhtml" = [ "firefox.desktop" ];
        "application/x-extension-xht" = [ "firefox.desktop" ];
        "application/xhtml+xml" = [ "firefox.desktop" ];
        #thunderbird
        "x-scheme-handler/mailto" = [ "thunderbird.desktop" ];
        "x-scheme-handler/mid" = [ "thunderbird.desktop" ];
        "x-scheme-handler/webcal" = [ "thunderbird.desktop" ];
        "x-scheme-handler/webcals" = [ "thunderbird.desktop" ];
        "application/x-extension-ics" = [ "thunderbird.desktop" ];
        "message/rfc822" = [ "thunderbird.desktop" ];
        "text/calendar" = [ "thunderbird.desktop" ];
      };
    };
  };

  # Mako (notification daemon)
  services.mako = {
    enable = true;
    settings = {
      border-radius = 4;
      border-size = 2;
      height = 300;
      group-by = "app-name";
      ignore-timeout = true;
      on-notify = "exec kill -35 $(pidof waybar)";
      on-button-left = "exec ${pkgs.mako}/bin/makoctl invoke -n \"$id\" && ${pkgs.mako}/bin/makoctl dismiss -n \"$id\" && kill -35 $(pidof waybar)";
      on-button-right = "exec ${pkgs.mako}/bin/makoctl dismiss -n \"$id\" && kill -35 $(pidof waybar)";
      "mode=doNotDisturb" = {
        invisible = 1;
      };
    };
  };

  # Waybar
  stylix.targets.waybar.enable = false; # my styling is better...
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = import ./waybar/config.nix { pkgs = pkgs; };
    style = (import ./waybar/style.nix) { config = config; };
  };
  xdg.configFile."mako.sh" = {
    target = "waybar/scripts/mako.sh";
    source = ./systemScripts/makoWaybar.sh;
    executable = true;
  };
  home.file = {
    "launch.sh" = {
      target = ".systemScripts/launch.sh";
      source = ./systemScripts/launch.sh;
      executable = true;
    };
  };

  programs.mpv = {
    enable = true;
    config = {
      profile = "gpu-hq";
      hwdec = "auto-safe";
      vo = "gpu";
      gpu-context = "wayland";
    };
  };

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-gstreamer
      obs-vaapi
      obs-pipewire-audio-capture
    ];
  };

  # Alacritty
  programs.alacritty = {
    enable = true;
    settings.keyboard.bindings = [
      {
        key = "Return";
        mods = "Control";
        action = "SpawnNewInstance";
      }
    ];
  };

  # virt-manager stu. See NixOS Wiki for more
  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };

  #more programs
  programs = {
    chromium.enable = true;
    htop = {
      enable = true;
      package = pkgs.htop-vim;
    };
  };

  # -- misc --
  # Disable baloo indexing service
  xdg.configFile."baloofilerc".text = ''
    [Basic Settings]
    Indexing-Enabled=false
  '';
}
