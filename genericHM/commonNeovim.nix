{ ... }:

# this is a neovim configuration for (pretty much) all my devices & users.
# basic stuff only 
# some devices/users may expand uppon this
{
  programs.nixvim = {
    enable = true;

    colorschemes.onedark.enable = true;

    globals = {
      mapleader = ",";
      maplocalleader = " ";
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

    autoCmd = [
      {	#change indentation for .nix files
        event = [
          "BufEnter"
          "BufWinEnter"
        ];
        pattern = [ "*.nix" "*.svelte" "*.ts" "*.html" ];	#set tabstop of 2 for nix files
        # Or use `vimCallback` with a vimscript function name
        # Or use `command` if you want to run a normal vimscript command
        command = "setlocal tabstop=2";
      }
    ];

    plugins = {
      #improved highlighting
      treesitter = {
        enable = true;
        disabledLanguages = [ "latex" ];
      };

      #shows indentation levels and variable scopes (treesitter)
      indent-blankline.enable = true;

      #automatically creates pairs of brackets, etc.
      nvim-autopairs.enable = true;

      #status bar at bottom
      lualine = {
        enable = true;
        theme = "onedark";
      };

      #nix and bash lsp 
      lsp = {
        enable = true;
        servers = {
          bashls.enable = true; #lsp server for bash 
          nil_ls.enable = true; #lsp server for Nix
        };
      };
      nvim-cmp = {
        enable = true;
        mapping = {
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
        sources = [
          { name = "nvim_lsp"; }
          { name = "path"; }
          { name = "buffer"; }
        ];
      };
    };
  };
}
