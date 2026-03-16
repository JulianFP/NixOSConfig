{ pkgs, ... }:

{
  home.packages = with pkgs; [
    #work
    teams-for-linux
  ];
}
