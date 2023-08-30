{ config, pkgs, ... }:

{
  programs.nixvim = {
    enable = true;
    
    colorschemes.gruvbox = {
      enable = true;
      contrastDark = "soft";
      improvedStrings = true;
      improvedWarnings = true;
      trueColor = true;
    };

    globals = {
      mapleader = ",";		#map leader key to comma
      maplocalleader = " ";	#map local leader key to space

      #for vimtex
      vimtex_view_general_viewer = "okular";
      vimtex_view_general_options = "--unique file:@pdf\#src:@line@tex";

      # for vimspector
      # vimspector_install_gadgets = [ "debugpy" "vscode-cpptools" "CodeLLDB" ];

      # for custom build and run commands
      dir = "%:p:h";
      folder = "%:p:h:t";
      file = "%:t";
    };

    options = {
      compatible = false; 	#disable compatibility to old-time vi
      showmatch = true; 	#show matching
      ignorecase = true; 	#case insensitive
      mouse = "a"; 		#enable mouse for all modes
      hlsearch = true; 		#highlight search
      incsearch = true; 	#incremental search
      tabstop = 4; 		#how wide tab character should be displayed
      softtabstop = 0; 		#how wide pressing tab should span (replicate tabstop)
      shiftwidth = 0; 		#how wide shift commands should be (replicate tabstop)
      expandtab = true; 	#converts tabs to white space
      shiftround = true;        #round indentation to multiples shiftwidth
      autoindent = true; 	#indent a new line the same amount as the line just typed
      smartindent = true;	#make smart indentation (after { and so on)
      number = true; 		#add line numbers
      cursorline = true;	#highlight current cursorline
      ttyfast = true;		#Speed up scrolling in Vim
      ve = "onemore";		#allow cursor to be at first empty space after line
      encoding = "utf8";

    };

    clipboard = {
      register = "unnamedplus";
      providers.wl-copy.enable = true;
    };

    # custom build and run commands (they depend on alacritty and a custom bash script)
    userCommands = {
      "CreateCMakeFile" = {
        command = "execute '!bash ~/.systemScripts/createCMakeFile.sh ' . g:folder . ' ' . g:file";
	bang = true;
	desc = "create CMakeFile and vimspector file for current project";
      };
      "BuildDebug" = {
        command = "!mkdir buildDebug -p && cd buildDebug && cmake -DCMAKE_BUILD_TYPE=Debug .. && make -j8";
	bang = true;
	desc = "builds the current project in debug mode (CreateCMakeFile has to run first)";
      };
      "BuildRelease" = {
        command = "!mkdir buildRelease -p && cd buildRelease && cmake -DCMAKE_BUILD_TYPE=Release .. && make -j8";
	bang = true;
	desc = "builds the current project in release mode (CreateCMakeFile has to run first)";
      };
      "RunDebug" = {
	command = "execute ':silent !alacritty --hold -e ~/.systemScripts/launch.sh ' . g:dir . ' buildDebug ' . g:folder";
	bang = true;
	desc = "runs debug binary of the current project (BuildDebug has to run first)";
      };
      "RunRelease" = {
        command = "execute ':silent !alacritty --hold -e ~/.systemScripts/launch.sh ' . g:dir . ' buildRelease ' . g:folder";
	bang = true;
	desc = "runs release binary of the current project (BuildRelease has to run first)";
      };
    };

    autoCmd = [
      {	#change indentation for .nix files
        event = [ 
	  "BufEnter"
	  "BufWinEnter"
        ];
        pattern = "*.nix";	#set tabstop of 2 for nix files
        # Or use `vimCallback` with a vimscript function name
        # Or use `command` if you want to run a normal vimscript command
        command = "setlocal tabstop=2";
      }
    ];

    maps = {
      # for normal,visual,select,operator-pending modes (map)
      normalVisualOp = {
        # set window navigation keys
        "<c-j>" = "'<c-w>j'";
	"<c-k>" = "'<c-w>k'";
	"<c-h>" = "'<c-w>h'";
	"<c-l>" = "'<c-w>l'";

	# for luasnips
        "<c-w>" = {
	  silent = true;
	  action = "<cmd>lua require('luasnip').jump(1)<Cr>";
	};
        "<c-b>" = {
	  silent = true;
	  action = "<cmd>lua require('luasnip').jump(-1)<Cr>";
	};
	"<c-n>" = {
	  silent = true;
	  action = "luasnip#choice_active() ? '<Plug>luasnip-next-choice'";
	};
      };

      # for insert mode
      insert = {
        # for luasnips
        "<c-w>" = {
	  silent = true;
	  action = "<cmd>lua require('luasnip').jump(1)<Cr>";
	};
        "<c-b>" = {
	  silent = true;
	  action = "<cmd>lua require('luasnip').jump(-1)<Cr>";
	};
	"<c-n>" = {
	  silent = true;
	  action = "luasnip#choice_active() ? '<Plug>luasnip-next-choice'";
	};
      };

      # for normal mode
      normal = {
        #for custom build and run
        "<Leader>bc" = ":CreateCMakeFile<CR>";
        "<Leader>bd" = ":BuildDebug<CR>";
        "<Leader>br" = ":BuildRelease<CR>";
        "<Leader>rd" = ":RunDebug<CR>";
        "<Leader>rr" = ":RunRelease<CR>";

	#for vimspector
	/*
	"<LocalLeader>c" = "<Plug>VimspectorContinue";
	"<LocalLeader>q" = ":call vimspector#Reset()<CR>";
	"<LocalLeader>r" = "<Plug>VimspectorRestart";
	"<LocalLeader>p" = "<Plug>VimspectorPause";
	"<LocalLeader>b" = "<Plug>VimspectorToggleBreakpoint";
	"<LocalLeader>o" = "<Plug>VimspectorToggleConditionalBreakpoint";
	"<LocalLeader>h" = "<Plug>VimspectorRunToCursor";
	"<LocalLeader>n" = "<Plug>VimspectorStepOver";
	"<LocalLeader>s" = "<Plug>VimspectorStepInto";
	"<LocalLeader>f" = "<Plug>VimspectorStepOut";
	"<LocalLeader>e" = "<Plug>VimspectorBalloonEval";
	"<LocalLeader>u" = "<Plug>VimspectorUpFrame";
	"<LocalLeader>d" = "<Plug>VimspectorDownFrame";
	"<LocalLeader>B" = "<Plug>VimspectorBreakpoints";
	"<LocalLeader>D" = "<Plug>VimspectorDisassemble";
	"<LocalLeader>t" = "<Plug>VimspectorShowOutput";
	*/
      };

      # for visual mode
      visual = {
        # for vimspector
	#"<LocalLeader>e" = "<Plug>VimspectorBalloonEval";
      };
    };

    plugins = {
      lualine = {
        enable = true;
	theme = "gruvbox";
      };

      luasnip = {
        enable = true;
	fromVscode = [
	  {
	    include = [
	      "bash"
	      "c"
	      "cpp"
	      "python"
	      "nix"
	      "latex"
	    ];
	  }
	];
      };
      indent-blankline.enable = true;
      nvim-autopairs.enable = true;
      vimtex.enable = true;

      lsp = {
        enable = true;
	servers = {
	  bashls.enable = true;	#lsp server for Bash
	  clangd.enable = true; #lsp server for C/C++
	  pyright.enable = true;#lsp server for Python
	  nil_ls.enable = true;	#lsp server for Nix
	  texlab.enable = true; #lsp Server for LaTeX
	};
      };
      nvim-cmp = {
        enable = true;
	mapping = {
	  "<Esc>" = "cmp.mapping.abort()";
	  "<CR>" = "cmp.mapping.confirm({select = true})";
	  "<Tab>" = {
	    modes = [ "i" "s" ];
	    action = ''
	      function(fallback)
		if cmp.visible() then
		  cmp.select_next_item()
		else
		  fallback()
		end
	      end
	    '';
	  };
	};
	snippet.expand = "luasnip";
	sources = [
          { name = "nvim_lsp"; }
          { name = "luasnip"; } #For luasnip users.
          { name = "path"; }
          { name = "buffer"; }
        ];
      };
    };
    extraPlugins = with pkgs.vimPlugins; [
      friendly-snippets
      #vimspector doesn't work currently because of gadgets it needs to install. Todo: contribute vimspector module to nixvim
      #vimspector
    ];
  };

  home.file = {
    "launch.sh" = {
      target = ".systemScripts/launch.sh";
      source = ./systemScripts/launch.sh;
      executable = true;
    };
    "createCMakeFile.sh" = {
      target = ".systemScripts/createCMakeFile.sh";
      source = ./systemScripts/createCMakeFile.sh;
      executable = true;
    };
  };
}
