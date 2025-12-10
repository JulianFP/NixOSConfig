{
  config,
  lib,
  pkgs,
  ...
}:

let

  #custom qtct color palette
  #inspiration from following base16 template: https://github.com/mnussbaum/base16-qt5ct
  qtct-color-file =
    with config.lib.stylix.colors;
    pkgs.writeText "stylix-qtct-colors.conf" ''
      [ColorScheme]
      active_colors=#ff${base05}, #ff${base01}, #ff${base01}, #ff${base02}, #ff${base03}, #ff${base04}, #ff${base05}, #ff${base06}, #ff${base05}, #ff${base00}, #ff${base00}, #ff${base03}, #ff${base0D}, #ff${base06}, #ff${base0B}, #ff${base0E}, #ff${base02}, #ff${base05}, #ff${base01}, #ff${base0C}, #ff${base0D}, #ff${base0D}
      disabled_colors=#ff${base04}, #ff${base00}, #ff${base01}, #ff${base02}, #ff${base03}, #ff${base04}, #ff${base04}, #ff${base04}, #ff${base04}, #ff${base00}, #ff${base00}, #ff${base03}, #ff${base02}, #ff${base06}, #ff${base0B}, #ff${base0E}, #ff${base01}, #ff${base05}, #ff${base01}, #ff${base0C}, #ff${base0D}, #ff${base0D}
      inactive_colors=#ff${base05}, #ff${base01}, #ff${base01}, #ff${base02}, #ff${base03}, #ff${base04}, #ff${base05}, #ff${base06}, #ff${base05}, #ff${base00}, #ff${base00}, #ff${base03}, #ff${base0D}, #ff${base06}, #ff${base0B}, #ff${base0E}, #ff${base01}, #ff${base05}, #ff${base01}, #ff${base0C}, #ff${base0D}, #ff${base0D}
    '';

  #custom KColorScheme definition, used for patched qt6ct and kdeglobals
  #Since KDE-Frameworks 6.8 this is the only way of theming some KDE apps (like dolphin, okular) outside of Plasma
  #see https://github.com/trialuser02/qt6ct/pull/43
  #also more in-depth explanation: https://nicolasfella.de/posts/how-platform-integration-works/
  #inspired by https://github.com/Base24/base16-kdeplasma
  kColorSchemeBasic =
    with config.lib.stylix.colors;
    let
      base00-rgb = "${base00-rgb-r},${base00-rgb-g},${base00-rgb-b}";
      base01-rgb = "${base01-rgb-r},${base01-rgb-g},${base01-rgb-b}";
      base02-rgb = "${base02-rgb-r},${base02-rgb-g},${base02-rgb-b}";
      base03-rgb = "${base03-rgb-r},${base03-rgb-g},${base03-rgb-b}";
      base04-rgb = "${base04-rgb-r},${base04-rgb-g},${base04-rgb-b}";
      base05-rgb = "${base05-rgb-r},${base05-rgb-g},${base05-rgb-b}";
      base0B-rgb = "${base0B-rgb-r},${base0B-rgb-g},${base0B-rgb-b}";
      base0C-rgb = "${base0C-rgb-r},${base0C-rgb-g},${base0C-rgb-b}";
      base0D-rgb = "${base0D-rgb-r},${base0D-rgb-g},${base0D-rgb-b}";
      base0E-rgb = "${base0E-rgb-r},${base0E-rgb-g},${base0E-rgb-b}";
      base0F-rgb = "${base0F-rgb-r},${base0F-rgb-g},${base0F-rgb-b}";
      common = {
        DecorationFocus = base0D-rgb;
        DecorationHover = base0D-rgb;
        ForegroundLink = base0B-rgb;
        ForegroundNegative = base0F-rgb;
        ForegroundNeutral = base04-rgb;
        ForegroundPositive = base0C-rgb;
        ForegroundVisited = base0E-rgb;
      };
      view = common // {
        BackgroundNormal = base01-rgb;
        BackgroundAlternate = base02-rgb;
        ForegroundNormal = base05-rgb;
        ForegroundActive = base05-rgb;
        ForegroundInactive = base03-rgb;
      };
    in
    {
      "ColorEffects:Disabled" = {
        Color = base01-rgb;
        ColorAmount = 0;
        ColorEffect = 0;
        ContrastAmount = 0.65;
        ContrastEffect = 1;
        IntensityAmount = 0.1;
        IntensityEffect = 2;
      };
      "ColorEffects:Inactive" = {
        ChangeSelectionColor = true;
        Color = base02-rgb;
        ColorAmount = 0.025;
        ColorEffect = 2;
        ContrastAmount = 0.1;
        ContrastEffect = 2;
        Enable = false;
        IntensityAmount = 0;
        IntensityEffect = 0;
      };
      "Colors:Button" = common // {
        BackgroundAlternate = base01-rgb;
        BackgroundNormal = base00-rgb;
        ForegroundNormal = base05-rgb;
        ForegroundActive = base05-rgb;
        ForegroundInactive = base03-rgb;
      };
      "Colors:Selection" = common // {
        BackgroundNormal = base0D-rgb;
        BackgroundAlternate = base0D-rgb;
        ForegroundNormal = base02-rgb;
        ForegroundActive = base0B-rgb;
        ForegroundInactive = base02-rgb;
      };
      "Colors:View" = view;
      "Colors:Tooltip" = view;
      "Colors:Window" = common // {
        BackgroundNormal = base00-rgb;
        BackgroundAlternate = base01-rgb;
        ForegroundNormal = base05-rgb;
        ForegroundActive = base05-rgb;
        ForegroundInactive = base02-rgb;
      };
      "WM" = {
        activeBackground = base00-rgb;
        activeBlend = base00-rgb;
        activeForeground = base05-rgb;
        inactiveBackground = base00-rgb;
        inactiveBlend = base00-rgb;
        inactiveForeground = base04-rgb;
      };
    };

  kColorScheme-INI = (
    lib.generators.toINI { } (
      kColorSchemeBasic
      // {
        General = {
          ColorScheme = "StylixDark";
          Name = "Stylix Dark";
          shadeSortColumn = true;
        };
        KDE.contrast = 4;
      }
    )
  );

  qtct-qss = ''
    QTabBar::tab:selected {
        color: palette(bright-text);
    }
    QScrollBar {
        background: palette(dark);
    }
    QScrollBar::handle {
        background: palette(highlight);
        border-radius: 4px;
    }
    QScrollBar::add-line, QScrollBar::sub-line {
        background: palette(window);
    }
  '';

in
{
  qt = {
    enable = true;
    platformTheme.name = "qtct";
  };
  home.packages = with pkgs; [
    kdePackages.breeze
  ];

  stylix.targets.qt.enable = false;

  #qtct config
  xdg.configFile = {
    "qt6ct/qt6ct.conf".text = ''
      [Appearance]
      color_scheme_path=${qtct-color-file}
      custom_palette=true
      icon_theme=Papirus-Dark
      style=Breeze

      [Fonts]
      fixed="${config.stylix.fonts.monospace.name},${builtins.toString config.stylix.fonts.sizes.applications},-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"
      general="${config.stylix.fonts.serif.name},${builtins.toString config.stylix.fonts.sizes.applications},-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"

      [Interface]
      stylesheets=${qtct-qss}
    '';

    "kdeglobals".text = (
      lib.generators.toINI { } (
        kColorSchemeBasic
        // {
          General.TerminalApplication = "alacritty";
          Icons.Theme = "Papirus-Dark";
          KDE = {
            SingleClick = false;
            LookAndFeelPackage = "org.kde.breezedark.desktop";
          };
          "KFileDialog Settings" = {
            "Allow Expansion" = false;
            "Automatically select filename extension" = true;
            "Breadcrumb Navigation" = true;
            "Decoration position" = 2;
            "LocationCombo Completionmode" = 5;
            "PathCombo Completionmode" = 5;
            "Show Bookmarks" = true;
            "Show Full Path" = true;
            "Show Inline Previews" = true;
            "Show Speedbar" = true;
            "Show hidden files" = true;
            "Sort by" = "Name";
            "Sort directories first" = false;
            "Sort hidden files last" = false;
            "Sort reversed" = false;
            "Speedbar Width" = 236;
            "View Style" = "DetailTree";
          };
        }
      )
    );
  };
}
