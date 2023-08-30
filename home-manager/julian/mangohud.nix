{ config, pkgs, ...} :

{
  programs.mangohud = {
    enable = true;
    enableSessionWide = true;
    settings = {
      legacy_layout = false;
      gpu_stats = true;
      graphs = [
        "gpu_load"
      ];
      gpu_temp = true;
      gpu_core_clock = true;
    };
  };
}
