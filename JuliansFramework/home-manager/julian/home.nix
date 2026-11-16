{ ... }:

{
  imports = [
    ./packages.nix
    ./hyprland.nix
  ];

  programs.opencode = {
    enable = true;
    settings = {
      disabled_providers = [ "opencode" ];
      plugins = [ "opencode-models-discovery@2.1.2" ];
      providers.kit-toolbox = {
        name = "KIT KI-Toolbox";
        package = "@opencode/ai/providers/openai-compatible";

        settings = {
          baseURL = "https://ki-toolbox.scc.kit.edu/api/v1";
          apiKey = "{file:/run/secrets/kit-toolbox-api-key}";
          modelsDiscovery = {
            enabled = true;
            endpoint = "/api/v1/models";
            timeoutMs = 10000;
            smartModelName = true;
            cache.enabled = false;
          };
        };
      };
    };
  };
}
