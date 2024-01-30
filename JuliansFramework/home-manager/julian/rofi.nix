{config, pkgs, nix-colors, ...}:

{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;

    #converted from this template: https://github.com/tinted-theming/base16-rofi
    theme = with config.colorScheme.palette; with nix-colors.lib.conversions;
    let
      inherit (config.lib.formats.rasi) mkLiteral;
    in {
      "*" = {
        red = mkLiteral "rgba ( ${hexToRGBString ", " base08}, 100 % )";
        blue = mkLiteral "rgba ( ${hexToRGBString ", " base0D}, 100 % )";
        lightfg = mkLiteral "rgba ( ${hexToRGBString ", " base06}, 100 % )";
        lightbg = mkLiteral "rgba ( ${hexToRGBString ", " base01}, 100 % )";
        foreground = mkLiteral "rgba ( ${hexToRGBString ", " base05}, 100 % )";
        background = mkLiteral "rgba ( ${hexToRGBString ", " base00}, 100 % )";
        background-color = mkLiteral "rgba ( ${hexToRGBString ", " base00}, 0 % )";
        separatorcolor = mkLiteral "@foreground";
        border-color = mkLiteral "@foreground";
        selected-normal-foreground = mkLiteral "@lightbg";
        selected-normal-background = mkLiteral "@lightfg";
        selected-active-foreground = mkLiteral "@background";
        selected-active-background = mkLiteral "@blue";
        selected-urgent-foreground = mkLiteral "@background";
        selected-urgent-background = mkLiteral "@red";
        normal-foreground = mkLiteral "@foreground";
        normal-background = mkLiteral "@background";
        active-foreground = mkLiteral "@blue";
        active-background = mkLiteral "@background";
        urgent-foreground = mkLiteral "@red";
        urgent-background = mkLiteral "@background";
        alternate-normal-foreground = mkLiteral "@foreground";
        alternate-normal-background = mkLiteral "@lightbg";
        alternate-active-foreground = mkLiteral "@blue";
        alternate-active-background = mkLiteral "@lightbg";
        alternate-urgent-foreground = mkLiteral "@red";
        alternate-urgent-background = mkLiteral "@lightbg";
        spacing = 2;
      };
      "window" = {
        background-color = mkLiteral "@background";
        border = 1;
        padding = 5;
      };
      "mainbox" = {
        border = 0;
        padding = 0;
      };
      "message" = {
        border = mkLiteral "1px dash 0px 0px";
        border-color = mkLiteral "@separatorcolor";
        padding = mkLiteral "1px";
      };
      "textbox" = {
        text-color = mkLiteral "@foreground";
      };
      "listview" = {
        fixed-height = 0;
        border = mkLiteral "2px dash 0px 0px";
        border-color = mkLiteral "@separatorcolor";
        spacing = mkLiteral "2px";
        scrollbar = true;
        padding = mkLiteral "2px 0px 0px";
      };
      "element-text, element-icon" = {
        background-color = mkLiteral "inherit";
        text-color = mkLiteral "inherit";
      };
      "element" = {
        border = 0;
        padding = mkLiteral "1px";
      };
      "element normal.normal" = {
        background-color = mkLiteral "@normal-background";
        text-color = mkLiteral "@normal-foreground";
      };
      "element normal.urgent" = {
        background-color = mkLiteral "@urgent-background";
        text-color = mkLiteral "@urgent-foreground";
      };
      "element normal.active" = {
        background-color = mkLiteral "@active-background";
        text-color = mkLiteral "@active-foreground";
      };
      "element selected.normal" = {
        background-color = mkLiteral "@selected-normal-background";
        text-color = mkLiteral "@selected-normal-foreground";
      };
      "element selected.urgent" = {
        background-color = mkLiteral "@selected-urgent-background";
        text-color = mkLiteral "@selected-urgent-foreground";
      };
      "element selected.active" = {
        background-color = mkLiteral "@selected-active-background";
        text-color = mkLiteral "@selected-active-foreground";
      };
      "element alternate.normal" = {
        background-color = mkLiteral "@alternate-normal-background";
        text-color = mkLiteral "@alternate-normal-foreground";
      };
      "element alternate.urgent" = {
        background-color = mkLiteral "@alternate-urgent-background";
        text-color = mkLiteral "@alternate-urgent-foreground";
      };
      "element alternate.active" = {
        background-color = mkLiteral "@alternate-active-background";
        text-color = mkLiteral "@alternate-active-foreground";
      };
      "scrollbar" = {
        width = mkLiteral "4px";
        border = 0;
        handle-color = mkLiteral "@normal-foreground";
        handle-width = mkLiteral "8px";
        padding = 0;
      };
      "sidebar" = {
        border = mkLiteral "2px dash 0px 0px";
        border-color = mkLiteral "@separatorcolor";
      };
      "button" = {
        spacing = 0;
        text-color = mkLiteral "@normal-foreground";
      };
      "button selected" = {
        background-color = mkLiteral "@selected-normal-background";
        text-color = mkLiteral "@selected-normal-foreground";
      };
      "inputbar" = {
        spacing = mkLiteral "0px";
        text-color = mkLiteral "@normal-foreground";
        padding = mkLiteral "1px";
        children = map mkLiteral [ "prompt" "textbox-prompt-colon" "entry" "case-indicator" ];
      };
      "case-indicator" = {
        spacing = 0;
        text-color = mkLiteral "@normal-foreground";
      };
      "entry" = {
        spacing = 0;
        text-color = mkLiteral "@normal-foreground";
      };
      "prompt" = {
        spacing = 0;
        text-color = mkLiteral "@normal-foreground";
      };
      "textbox-prompt-colon" = {
        expand = false;
        str = ":";
        margin = mkLiteral "0px 0.3000em 0.0000em 0.0000em";
        text-color = mkLiteral "inherit";
      };
    };

    terminal = "${pkgs.alacritty}/bin/alacritty";
    font = "Roboto Mono Medium 14";
  };
}
