{ config, pkgs, ... }:

{
  programs.rofi = {
    enable = true;

    #converted from this template: https://github.com/tinted-theming/base16-rofi
    theme =
      let
        inherit (config.lib.formats.rasi) mkLiteral;
      in
      {
        "*" = {
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
          border = 1;
          padding = 5;
        };
        "mainbox" = {
          border = 0;
          padding = 0;
        };
        "message" = {
          border = mkLiteral "1px dash 0px 0px";
          padding = mkLiteral "1px";
        };
        "listview" = {
          fixed-height = 0;
          border = mkLiteral "2px dash 0px 0px";
          spacing = mkLiteral "2px";
          scrollbar = true;
          padding = mkLiteral "2px 0px 0px";
        };
        "element" = {
          border = 0;
          padding = mkLiteral "1px";
        };
        "scrollbar" = {
          width = mkLiteral "4px";
          border = 0;
          handle-width = mkLiteral "8px";
          padding = 0;
        };
        "sidebar" = {
          border = mkLiteral "2px dash 0px 0px";
        };
        "button" = {
          spacing = 0;
        };
        "inputbar" = {
          spacing = mkLiteral "0px";
          padding = mkLiteral "1px";
          children = map mkLiteral [
            "prompt"
            "textbox-prompt-colon"
            "entry"
            "case-indicator"
          ];
        };
        "case-indicator" = {
          spacing = 0;
        };
        "entry" = {
          spacing = 0;
        };
        "prompt" = {
          spacing = 0;
        };
        "textbox-prompt-colon" = {
          expand = false;
          str = ":";
          margin = mkLiteral "0px 0.3000em 0.0000em 0.0000em";
        };
      };

    terminal = "${pkgs.alacritty}/bin/alacritty";
  };
}
