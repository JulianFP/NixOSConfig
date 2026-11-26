{ lib, ... }:

{
  imports = [
    ./packages.nix
    ./hyprland.nix
  ];

  home.file.".ssh/prakti_ws26_max.pub" = {
    source = ../../../publicKeys/prakti_ws26_max.pub;
  };
  programs.ssh.settings."FZI" = {
    HostName = "141.21.44.116";
    User = "prakti_ws26_max";
    Port = 1422;
    IdentityFile = "~/.ssh/prakti_ws26_max";
  };

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

          # Allow some git commands
          gitStatus = entryAfter [ "skill" ] (rule "shell" "git status *" "allow");
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
  xdg.configFile."opencode/AGENTS.md".text = ''
    # Rule: never use the shell when a dedicated tool can do the job

    Before every `shell` call, ask: "Is there a built-in tool for this?" If yes,
    use the tool. The shell is a last resort, reserved for tasks that genuinely
    require it (builds, tests, package managers, git, processes, or anything
    with no dedicated tool).

    | Instead of shell                        | Use                                        |
    | --------------------------------------- | ------------------------------------------ |
    | `ls`, `find`, `tree`                    | `glob`, or `read` on a directory           |
    | `grep`, `rg`, `ack`                     | `grep`                                     |
    | `cat`, `head`, `tail`, `less`, `nl`     | `read` (with `offset`/`limit` for slices)  |
    | `sed`, `awk`, `perl` inline edits       | `edit`                                     |
    | `echo >`, `tee`, `cp`, `mv`, `rm`       | `write`                                    |
    | `printf` to compose output for the user | Answer directly in your reply              |

    Also prefer batching independent tool calls in parallel instead of chaining
    shell commands with `;`, `&&`, or `echo "---"` separators.
  '';
}
