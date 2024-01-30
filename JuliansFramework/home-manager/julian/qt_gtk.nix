{ config, pkgs, nix-colors, ...}:

let
  nix-colors-lib = nix-colors.lib.contrib { inherit pkgs; };
in
{
  qt = {
    enable = true;
    style.name = "breeze";
    platformTheme = "kde";
  };

  #inspired by https://github.com/Base24/base16-kdeplasma
  xdg.configFile."kdeglobals".text = with config.colorScheme.palette; with nix-colors.lib.conversions; ''
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
