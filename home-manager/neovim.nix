{ config, pkgs, ... }:

{
  programs.nixneovim = {
    enable = true;
    defaultEditor = true;
    
    # currently doesn't work for some reason, so replaced by gruvbox-baby
    #colorschemes.gruvbox-material = {
    #  enable = true;
    #  background = "soft";
    #  betterPerformance = true;
    #};
    colorschemes.gruvbox-baby.enable = true;

    globals = {
      mapleader = ",";		#map leader key to comma
      maplocalleader = " ";	#map local leader key to space

      #for vimtex
      vimtex_view_general_viewer = "okular";
      vimtex_view_general_options = "--unique file:@pdf\#src:@line@tex";
    };

    options = {
      compatible = false; 	#disable compatibility to old-time vi
      showmatch = true; 	#show matching
      ignorecase = true; 	#case insensitive
      mouse = "v"; 		#middle-click paste with
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
      clipboard = "unnamedplus";#using system clipboard
      cursorline = true;	#highlight current cursorline
      ttyfast = true;		#Speed up scrolling in Vim
      ve = "onemore";		#allow cursor to be at first empty space after line
    };

    augroups = {
      intendationExceptions = {	#set different intendation for some filetypes
        autocmds = [{
          event = [ 
	    "BufEnter"
	    "BufWinEnter"
	  ];
          pattern = "*.nix";	#set tabstop of 2 for nix files
          # Or use `vimCallback` with a vimscript function name
          # Or use `command` if you want to run a normal vimscript command
	  command = "setlocal tabstop=2";
        }];
      };
    };

    mappings = {
      # for normal,visual,select,operator-pending modes (map)
      normalVisualOp = {
        # set window navigation keys
        "<c-j>" = "'<c-w>j'";
	"<c-k>" = "'<c-w>k'";
	"<c-h>" = "'<c-w>h'";
	"<c-l>" = "'<c-w>l'";
      };
      # for normal mode (nmap)
      normal = {
        
      };
      #for visual and select modes (vmap)
      visual = {
        
      };
      #for visual mode (xmap)
      visualOnly = {
        
      };
    };

    plugins = {
      lualine = {
        enable = true;
	theme = "gruvbox-baby";
      };

      luasnip = {
        enable = true;
	enableLua = false;
	enableSnipmate = true;
	path = "./snippets";
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
	  nil.enable = true;	#lsp server for Nix
	  texlab.enable = true; #lsp Server for LaTeX
	};
      };
      lsp-progress.enable = true;
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
	snippet.luasnip.enable = true;
	sources = {
	  buffer.enable = true;
	  luasnip.enable = true;
	  nvim_lsp.enable = true; 
	};
      };
    };
  };

  # import snippets for luasnip
  xdg.configFile."nvim/snippets" = {
    source = ./snippets;
    recursive = true;
  };
}
