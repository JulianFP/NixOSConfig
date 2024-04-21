{ config, pkgs, nix-colors, ...}:

let
  nix-colors-lib = nix-colors.lib.contrib { inherit pkgs; };

  #custom qtct color palette
  #inspiration from following base16 template: https://github.com/mnussbaum/base16-qt5ct
  qtct-color-file = with config.colorScheme.palette; pkgs.writeText "${config.colorScheme.slug}-qtct-colors.conf" ''
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
in
{
  qt = {
    enable = true;
    style.package = pkgs.kdePackages.breeze;
    platformTheme.name = "qtct";
  };

  #qtct config
  xdg.configFile = {
    "qt5ct/qt5ct.conf".text = ''
      [Appearance]
      color_scheme_path=${qtct-color-file}
      custom_palette=true 
      icon_theme=Papirus-Dark
      style=Breeze

      [Interface]
      stylesheets=${qtct-qss}
    '';

    "qt6ct/qt6ct.conf".text = ''
      [Appearance]
      color_scheme_path=${qtct-color-file}
      custom_palette=true 
      icon_theme=Papirus-Dark
      style=Breeze

      [Interface]
      stylesheets=${qtct-qss}
    '';

    #necessary for theming with plasma-integration e.g. under plasma
    #still here since some stuff is still accessed by some apps
    #colors still here because of KColorScheme: https://nicolasfella.de/posts/how-platform-integration-works/
    #inspired by https://github.com/Base24/base16-kdeplasma
    "kdeglobals".text = with config.colorScheme.palette; with nix-colors.lib.conversions; ''
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
      BackgroundAlternate=${hexToRGBString "," base01}
      BackgroundNormal=${hexToRGBString "," base00}
      DecorationFocus=${hexToRGBString "," base0D}
      DecorationHover=${hexToRGBString "," base0D}
      ForegroundActive=${hexToRGBString "," base0B}
      ForegroundInactive=${hexToRGBString "," base05}
      ForegroundLink=${hexToRGBString "," base09}
      ForegroundNegative=${hexToRGBString "," base0F}
      ForegroundNeutral=${hexToRGBString "," base04}
      ForegroundNormal=${hexToRGBString "," base05}
      ForegroundPositive=${hexToRGBString "," base0C}
      ForegroundVisited=${hexToRGBString "," base0E}

      [Colors:Selection]
      BackgroundAlternate=${hexToRGBString "," base0D}
      BackgroundNormal=${hexToRGBString "," base0D}
      DecorationFocus=${hexToRGBString "," base0D}
      DecorationHover=${hexToRGBString "," base0D}
      ForegroundActive=${hexToRGBString "," base0B}
      ForegroundInactive=${hexToRGBString "," base02}
      ForegroundLink=${hexToRGBString "," base09}
      ForegroundNegative=${hexToRGBString "," base0F}
      ForegroundNeutral=${hexToRGBString "," base04}
      ForegroundNormal=${hexToRGBString "," base02}
      ForegroundPositive=${hexToRGBString "," base0C}
      ForegroundVisited=${hexToRGBString "," base0E}

      [Colors:Tooltip]
      BackgroundAlternate=${hexToRGBString "," base02}
      BackgroundNormal=${hexToRGBString "," base01}
      DecorationFocus=${hexToRGBString "," base0D}
      DecorationHover=${hexToRGBString "," base0D}
      ForegroundActive=${hexToRGBString "," base0B}
      ForegroundInactive=${hexToRGBString "," base05}
      ForegroundLink=${hexToRGBString "," base09}
      ForegroundNegative=${hexToRGBString "," base0F}
      ForegroundNeutral=${hexToRGBString "," base04}
      ForegroundNormal=${hexToRGBString "," base05}
      ForegroundPositive=${hexToRGBString "," base0C}
      ForegroundVisited=${hexToRGBString "," base0E}

      [Colors:View]
      BackgroundAlternate=${hexToRGBString "," base02}
      BackgroundNormal=${hexToRGBString "," base01}
      DecorationFocus=${hexToRGBString "," base0D}
      DecorationHover=${hexToRGBString "," base0D}
      ForegroundActive=${hexToRGBString "," base0B}
      ForegroundInactive=${hexToRGBString "," base05}
      ForegroundLink=${hexToRGBString "," base09}
      ForegroundNegative=${hexToRGBString "," base0F}
      ForegroundNeutral=${hexToRGBString "," base04}
      ForegroundNormal=${hexToRGBString "," base05}
      ForegroundPositive=${hexToRGBString "," base0C}
      ForegroundVisited=${hexToRGBString "," base0E}

      [Colors:Window]
      BackgroundAlternate=${hexToRGBString "," base01}
      BackgroundNormal=${hexToRGBString "," base00}
      DecorationFocus=${hexToRGBString "," base0D}
      DecorationHover=${hexToRGBString "," base0D}
      ForegroundActive=${hexToRGBString "," base0B}
      ForegroundInactive=${hexToRGBString "," base05}
      ForegroundLink=${hexToRGBString "," base09}
      ForegroundNegative=${hexToRGBString "," base0F}
      ForegroundNeutral=${hexToRGBString "," base04}
      ForegroundNormal=${hexToRGBString "," base05}
      ForegroundPositive=${hexToRGBString "," base0C}
      ForegroundVisited=${hexToRGBString "," base0E}

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
      activeBackground=${hexToRGBString "," base00}
      activeBlend=${hexToRGBString "," base00}
      activeForeground=${hexToRGBString "," base05}
      inactiveBackground=${hexToRGBString "," base00}
      inactiveBlend=${hexToRGBString "," base00}
      inactiveForeground=${hexToRGBString "," base04}
    '';
  };

  #gtk theming
  gtk = {
    enable = true;
    theme.package = nix-colors-lib.gtkThemeFromScheme {
      scheme = config.colorScheme;
    };
    theme.name = config.colorScheme.slug;
    iconTheme.package = pkgs.papirus-icon-theme;
    iconTheme.name = "Papirus-Dark";
  };

  #cursor style
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.capitaine-cursors;
    name = "capitaine-cursors";
    size = 24;
  };
}
