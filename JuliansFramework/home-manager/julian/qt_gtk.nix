{ config, pkgs, ...}:

let

  #custom qtct color palette
  #inspiration from following base16 template: https://github.com/mnussbaum/base16-qt5ct
  qtct-color-file = with config.lib.stylix.colors; pkgs.writeText "stylix-qtct-colors.conf" ''
    [ColorScheme]
    active_colors=#ff${base05}, #ff${base01}, #ff${base01}, #ff${base02}, #ff${base03}, #ff${base04}, #ff${base05}, #ff${base06}, #ff${base05}, #ff${base00}, #ff${base00}, #ff${base03}, #ff${base0D}, #ff${base06}, #ff${base0B}, #ff${base0E}, #ff${base01}, #ff${base05}, #ff${base01}, #ff${base0C}, #8f${base04}
    disabled_colors=#ff${base04}, #ff${base00}, #ff${base01}, #ff${base02}, #ff${base03}, #ff${base04}, #ff${base04}, #ff${base04}, #ff${base04}, #ff${base00}, #ff${base00}, #ff${base03}, #ff${base02}, #ff${base06}, #ff${base0B}, #ff${base0E}, #ff${base01}, #ff${base05}, #ff${base01}, #ff${base0C}, #8f${base04}
    inactive_colors=#ff${base05}, #ff${base01}, #ff${base01}, #ff${base02}, #ff${base03}, #ff${base04}, #ff${base05}, #ff${base06}, #ff${base05}, #ff${base00}, #ff${base00}, #ff${base03}, #ff${base0D}, #ff${base06}, #ff${base0B}, #ff${base0E}, #ff${base01}, #ff${base05}, #ff${base01}, #ff${base0C}, #8f${base04}
  '';

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

  qtct-configFile = ''
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
in
{
  qt = {
    enable = true;
    style.package = pkgs.kdePackages.breeze;
    platformTheme.name = "qtct";
  };

  #qtct config
  xdg.configFile = {
    "qt5ct/qt5ct.conf".text = qtct-configFile;
    "qt6ct/qt6ct.conf".text = qtct-configFile;

    #necessary for theming with plasma-integration e.g. under plasma
    #still here since some stuff is still accessed by some apps
    #colors still here because of KColorScheme: https://nicolasfella.de/posts/how-platform-integration-works/
    #inspired by https://github.com/Base24/base16-kdeplasma
    "kdeglobals".text = with config.lib.stylix.colors; ''
      [ColorEffects:Disabled]
      ChangeSelectionColor=
      Color=56,56,56
      ColorAmount=1
      ColorEffect=0
      ContrastAmount=0.5
      ContrastEffect=1
      Enable=
      IntensityAmount=0
      IntensityEffect=2

      [ColorEffects:Inactive]
      ChangeSelectionColor=true
      Color=112,111,110
      ColorAmount=-0.9500000000000001
      ColorEffect=0
      ContrastAmount=0.6000000000000001
      ContrastEffect=0
      Enable=false
      IntensityAmount=0
      IntensityEffect=0

      [Colors:Button]
      BackgroundAlternate=${base01-rgb-r},${base01-rgb-g},${base01-rgb-b}
      BackgroundNormal=${base00-rgb-r},${base00-rgb-g},${base00-rgb-b}
      DecorationFocus=${base0D-rgb-r},${base0D-rgb-g},${base0D-rgb-b}
      DecorationHover=${base0D-rgb-r},${base0D-rgb-g},${base0D-rgb-b}
      ForegroundActive=${base0B-rgb-r},${base0B-rgb-g},${base0B-rgb-b}
      ForegroundInactive=${base05-rgb-r},${base05-rgb-g},${base05-rgb-b}
      ForegroundLink=${base09-rgb-r},${base09-rgb-g},${base09-rgb-b}
      ForegroundNegative=${base0F-rgb-r},${base0F-rgb-g},${base0F-rgb-b}
      ForegroundNeutral=${base04-rgb-r},${base04-rgb-g},${base04-rgb-b}
      ForegroundNormal=${base05-rgb-r},${base05-rgb-g},${base05-rgb-b}
      ForegroundPositive=${base0C-rgb-r},${base0C-rgb-g},${base0C-rgb-b}
      ForegroundVisited=${base0E-rgb-r},${base0E-rgb-g},${base0E-rgb-b}

      [Colors:Selection]
      BackgroundAlternate=${base0D-rgb-r},${base0D-rgb-g},${base0D-rgb-b}
      BackgroundNormal=${base0D-rgb-r},${base0D-rgb-g},${base0D-rgb-b}
      DecorationFocus=${base0D-rgb-r},${base0D-rgb-g},${base0D-rgb-b}
      DecorationHover=${base0D-rgb-r},${base0D-rgb-g},${base0D-rgb-b}
      ForegroundActive=${base0B-rgb-r},${base0B-rgb-g},${base0B-rgb-b}
      ForegroundInactive=${base02-rgb-r},${base02-rgb-g},${base02-rgb-b}
      ForegroundLink=${base09-rgb-r},${base09-rgb-g},${base09-rgb-b}
      ForegroundNegative=${base0F-rgb-r},${base0F-rgb-g},${base0F-rgb-b}
      ForegroundNeutral=${base04-rgb-r},${base04-rgb-g},${base04-rgb-b}
      ForegroundNormal=${base02-rgb-r},${base02-rgb-g},${base02-rgb-b}
      ForegroundPositive=${base0C-rgb-r},${base0C-rgb-g},${base0C-rgb-b}
      ForegroundVisited=${base0E-rgb-r},${base0E-rgb-g},${base0E-rgb-b}

      [Colors:Tooltip]
      BackgroundAlternate=${base02-rgb-r},${base02-rgb-g},${base02-rgb-b}
      BackgroundNormal=${base01-rgb-r},${base01-rgb-g},${base01-rgb-b}
      DecorationFocus=${base0D-rgb-r},${base0D-rgb-g},${base0D-rgb-b}
      DecorationHover=${base0D-rgb-r},${base0D-rgb-g},${base0D-rgb-b}
      ForegroundActive=${base0B-rgb-r},${base0B-rgb-g},${base0B-rgb-b}
      ForegroundInactive=${base05-rgb-r},${base05-rgb-g},${base05-rgb-b}
      ForegroundLink=${base09-rgb-r},${base09-rgb-g},${base09-rgb-b}
      ForegroundNegative=${base0F-rgb-r},${base0F-rgb-g},${base0F-rgb-b}
      ForegroundNeutral=${base04-rgb-r},${base04-rgb-g},${base04-rgb-b}
      ForegroundNormal=${base05-rgb-r},${base05-rgb-g},${base05-rgb-b}
      ForegroundPositive=${base0C-rgb-r},${base0C-rgb-g},${base0C-rgb-b}
      ForegroundVisited=${base0E-rgb-r},${base0E-rgb-g},${base0E-rgb-b}

      [Colors:View]
      BackgroundAlternate=${base02-rgb-r},${base02-rgb-g},${base02-rgb-b}
      BackgroundNormal=${base01-rgb-r},${base01-rgb-g},${base01-rgb-b}
      DecorationFocus=${base0D-rgb-r},${base0D-rgb-g},${base0D-rgb-b}
      DecorationHover=${base0D-rgb-r},${base0D-rgb-g},${base0D-rgb-b}
      ForegroundActive=${base0B-rgb-r},${base0B-rgb-g},${base0B-rgb-b}
      ForegroundInactive=${base05-rgb-r},${base05-rgb-g},${base05-rgb-b}
      ForegroundLink=${base09-rgb-r},${base09-rgb-g},${base09-rgb-b}
      ForegroundNegative=${base0F-rgb-r},${base0F-rgb-g},${base0F-rgb-b}
      ForegroundNeutral=${base04-rgb-r},${base04-rgb-g},${base04-rgb-b}
      ForegroundNormal=${base05-rgb-r},${base05-rgb-g},${base05-rgb-b}
      ForegroundPositive=${base0C-rgb-r},${base0C-rgb-g},${base0C-rgb-b}
      ForegroundVisited=${base0E-rgb-r},${base0E-rgb-g},${base0E-rgb-b}

      [Colors:Window]
      BackgroundAlternate=${base01-rgb-r},${base01-rgb-g},${base01-rgb-b}
      BackgroundNormal=${base00-rgb-r},${base00-rgb-g},${base00-rgb-b}
      DecorationFocus=${base0D-rgb-r},${base0D-rgb-g},${base0D-rgb-b}
      DecorationHover=${base0D-rgb-r},${base0D-rgb-g},${base0D-rgb-b}
      ForegroundActive=${base0B-rgb-r},${base0B-rgb-g},${base0B-rgb-b}
      ForegroundInactive=${base05-rgb-r},${base05-rgb-g},${base05-rgb-b}
      ForegroundLink=${base09-rgb-r},${base09-rgb-g},${base09-rgb-b}
      ForegroundNegative=${base0F-rgb-r},${base0F-rgb-g},${base0F-rgb-b}
      ForegroundNeutral=${base04-rgb-r},${base04-rgb-g},${base04-rgb-b}
      ForegroundNormal=${base05-rgb-r},${base05-rgb-g},${base05-rgb-b}
      ForegroundPositive=${base0C-rgb-r},${base0C-rgb-g},${base0C-rgb-b}
      ForegroundVisited=${base0E-rgb-r},${base0E-rgb-g},${base0E-rgb-b}

      [General]
      TerminalApplication=alacritty

      [Icons]
      Theme=Papirus-Dark

      [KDE]
      SingleClick=false
      LookAndFeelPackage=org.kde.breezedark.desktop

      [KFileDialog Settings]
      Allow Expansion=false
      Automatically select filename extension=true
      Breadcrumb Navigation=true
      Decoration position=2
      LocationCombo Completionmode=5
      PathCombo Completionmode=5
      Show Bookmarks=true
      Show Full Path=true
      Show Inline Previews=true
      Show Speedbar=true
      Show hidden files=true
      Sort by=Name
      Sort directories first=false
      Sort hidden files last=false
      Sort reversed=false
      Speedbar Width=236
      View Style=DetailTree

      [WM]
      activeBackground=${base00-rgb-r},${base00-rgb-g},${base00-rgb-b}
      activeBlend=${base00-rgb-r},${base00-rgb-g},${base00-rgb-b}
      activeForeground=${base05-rgb-r},${base05-rgb-g},${base05-rgb-b}
      inactiveBackground=${base00-rgb-r},${base00-rgb-g},${base00-rgb-b}
      inactiveBlend=${base00-rgb-r},${base00-rgb-g},${base00-rgb-b}
      inactiveForeground=${base04-rgb-r},${base04-rgb-g},${base04-rgb-b}
    '';
  };

  #all other gtk stuff is done by stylix
  gtk.iconTheme = {
    package = pkgs.papirus-icon-theme;
    name = "Papirus-Dark";
  };
}
