{ lib, ... }:

{
  imports = [
    ./packages.nix
    ./hyprland.nix
  ];

  programs.opencode = {
    enable = true;
    settings =
      let
        inherit (lib.hm.dag) entryAnywhere entryAfter topoSort;

        # Construct an ordered permission rule.
        rule = action: resource: effect: {
          inherit action resource effect;
        };

        # Resolve a DAG of rules into an ordered list of plain rules.
        orderRules =
          dag:
          let
            sorted = topoSort dag;
          in
          if sorted ? result then
            map (entry: entry.data) sorted.result
          else
            throw "opencode permissions contain a cycle: ${builtins.toJSON sorted}";
      in
      {
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
        permissions = orderRules {
          # Default: ask for everything.
          default = entryAnywhere (rule "*" "*" "ask");

          # Allow ordinary file inspection inside the workspace.
          read = entryAfter [ "default" ] (rule "read" "*" "allow");
          glob = entryAfter [ "read" ] (rule "glob" "*" "allow");
          grep = entryAfter [ "glob" ] (rule "grep" "*" "allow");

          # Allow some non-destructive tools
          question = entryAfter [ "grep" ] (rule "question" "*" "allow");
          subagent = entryAfter [ "question" ] (rule "subagent" "*" "allow");
          skill = entryAfter [ "subagent" ] (rule "skill" "*" "allow");
          webfetch = entryAfter [ "skill" ] (rule "webfetch" "*" "allow");
          websearch = entryAfter [ "webfetch" ] (rule "websearch" "*" "allow");

          # Allow some git commands
          gitStatus = entryAfter [ "grep" ] (rule "shell" "git status *" "allow");
          gitDiff = entryAfter [ "gitStatus" ] (rule "shell" "git diff *" "allow");
          gitLog = entryAfter [ "gitDiff" ] (rule "shell" "git log *" "allow");
          gitShow = entryAfter [ "gitLog" ] (rule "shell" "git show *" "allow");

          # Protect environment files.
          env = entryAfter [ "gitShow" ] (rule "read" "*.env" "ask");
          envNested = entryAfter [ "env" ] (rule "read" "*.env.*" "ask");
        };

        agents = {
          build.permissions = [
            (rule "edit" "*" "allow")
            (rule "write" "*" "allow")
            (rule "patch" "*" "allow")
          ];
          plan.permissions = [
            (rule "edit" "*" "deny")
            (rule "write" "*" "deny")
            (rule "patch" "*" "deny")
          ];
        };
      };
  };
}
