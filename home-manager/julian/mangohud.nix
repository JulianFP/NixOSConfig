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
        "cpu_load"
      ];
      gpu_temp = true;
      gpu_core_clock = true;
      gpu_mem_clock = true;
      gpu_power = true;
      gpu_load_change = true;
      gpu_load_value= [ 50 90 ]; 
      gpu_load_color = [ "FFFFFF" "FFAA7F" "CC0000" ];
      gpu_text = "GPU";
      cpu_stats = true;
      cpu_temp = true;
      core_load = true;
      cpu_mhz = true;
      cpu_load_change = true;
      cpu_load_value = [ 50 90];
      cpu_load_color = [ "FFFFFF" "FFAA7F" "CC0000" ];
      cpu_color = "2E97CB";
      cpu_text = "CPU";
      io_color = "A491D3";
      swap = true;
      vram = true;
      vram_color = "AD64C1";
      ram = true;
      ram_color = "C26693";
      fps = true;
      engine_color = "EB5B5B";
      gpu_color = "2E9762";
      wine_color = "EB5B5B";
      frame_timing = 0;
      frametime_color = "00FF00";
      media_player_color = "FFFFFF";
      table_columns = 3;
      background_alpha = 0.4;
      font_size = 24;

      background_color = "020202";
      position = "top-left";
      text_color = "FFFFFF";
      round_corners = 5;
      toggle_hud = "Shift_R+F12";
      toggle_logging = "Shift_L+F2";
      upload_log = "F5";
      output_folder=/home/julian/Documents;
    };

    settingsPerApplication = {
      mpv = {
        no_display = true;
      };
    };
  };
}
