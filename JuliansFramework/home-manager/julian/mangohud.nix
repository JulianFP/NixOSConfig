{ config, pkgs, ...} :

{
  programs.mangohud = {
    enable = true;
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
      gpu_text = "GPU";
      cpu_stats = true;
      cpu_temp = true;
      core_load = true;
      cpu_mhz = true;
      cpu_load_change = true;
      cpu_load_value = [ 50 90];
      cpu_text = "CPU";
      swap = true;
      vram = true;
      ram = true;
      fps = true;
      frame_timing = 0;
      table_columns = 3;

      position = "top-left";
      round_corners = 5;
      toggle_hud = "Shift_R+F12";
      toggle_logging = "Shift_L+F2";
      upload_log = "F5";
      output_folder=/home/julian/Documents;
    };
  };
}
