{ config, ... }:

# config for some shell stuff shared by julian and root user of JuliansFramework
{
  imports = [ ./commonNeovim.nix ];

  #zsh
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      # set vi and vim as aliases for neovim
      vi = "nvim";
      vim = "nvim";
      sudo = "sudo "; # https://askubuntu.com/questions/22037/aliases-not-available-when-using-sudo
      root = "machinectl shell --uid 0";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      custom = if config.home.username == "root" then "$HOME/.ohMyZshCustom" else "";
      theme = if config.home.username == "root" then "juanghurtado-rootPatch" else "juanghurtado";
    };

    #environmental variables for zsh session
    sessionVariables = {
      EDITOR = "nvim"; # set neovim as default editor
    };
  };

  #ssh
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "Ionos1" = {
        hostname = "82.165.49.241";
        user = "root";
      };
      "Ionos2" = {
        hostname = "85.215.33.173";
        user = "root";
      };
      "project-w_urz" = {
        hostname = "project-w.urz.uni-heidelberg.de";
        user = "debian";
      };
      "project-w-runner_urz" = {
        hostname = "129.206.119.205";
        user = "localadmin";
      };
      "project-w-runner_urz_2" = {
        hostname = "129.206.119.206";
        user = "localadmin";
      };
      "ssc-whisper" = {
        hostname = "ssc-whisper.iwr.uni-heidelberg.de";
        user = "jpartanen";
      };
    };
  };

  # git
  programs.git = {
    enable = true;
    userName = "JulianFP";
    userEmail = "julian@partanengroup.de";
    #a lot of this is stolen from this great blog post: https://blog.gitbutler.com/how-git-core-devs-configure-git/
    extraConfig = {
      column.ui = "auto"; # makes commands like git branch, git status, git tag print their output in multiple columns
      branch.sort = "-committerdate"; # sort branches in git branch output by commit date instead of alphabetically
      tag.sort = "version:refname"; # sort tags by version number instead of alphabetically
      init.defaultBranch = "main"; # change default branch for git init
      diff = {
        algorithm = "histogram"; # improved version of the default diff algorithm that shows better/easier to understand output in some cases
        colorMoved = "plain"; # instead of just showing as deletion and insertion highlight moved code in different colors
        mnemonicPrefix = true; # instead of generic a/ b/ prefixes use prefixes to indicate what actually is being compared, e.g. index vs. working tree
        renames = true; # detect if file has been renamed
      };
      push = {
        autoSetupRemote = true; # automatically create remote branch if it doesn't exist yet
        followTags = true; # also push all local tags
      };
      fetch = {
        #prune branches, tags, etc. if deleted remotely
        prune = true;
        pruneTags = true;
        all = true;
      };
      pull.rebase = true; # automatically rebase on pull
      help.autocorrect = "prompt"; # If a command was mistyped git tries to guess the correct command and asks if that should be run instead
      commit.verbose = true; # show git diff in git commit window to help with writing commit messages
    };
  };

  home.file.".ohMyZshCustom/themes/juanghurtado-rootPatch.zsh-theme" = {
    enable = if config.home.username == "root" then true else false;
    source = ./juanghurtado-rootPatch.zsh-theme;
  };
}
