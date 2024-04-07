{ lib, stable, ... }:

# this is a neovim configuration for (pretty much) all my devices & users.
# basic stuff only 
# some devices/users may expand uppon this
let
  myOptions = {
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
    spelllang = "en_us";
    spell = true;
    spelloptions = "camel";
  };
in
{
  programs.nixvim = {
    enable = true;

    colorschemes.onedark.enable = true;

    globals = {
      mapleader = ",";
      maplocalleader = " ";
    };

    autoCmd = [
      {	#set indentation of some file types to 2
        event = [
          "BufEnter"
          "BufWinEnter"
        ];
        pattern = [ "*.nix" "*.svelte" "*.ts" "*.html" ];
        # Or use `vimCallback` with a vimscript function name
        # Or use `command` if you want to run a normal vimscript command
        command = "setlocal tabstop=2";	#set tabstop of 2
      }
      {	#set indentation of reStructuredText files to 3 (because rst is weird)
        event = [
          "BufEnter"
          "BufWinEnter"
        ];
        pattern = [ "*.rst" ];
        command = "setlocal tabstop=3";	#set tabstop of 3
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
      lsp-lines = {
        enable = true; #show lsp in virtual line
        currentLine = true;
      };
    }
    // lib.optionalAttrs (stable) {
      nvim-cmp = lib.mkIf stable { #for 23.11 devices
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
    }#has moved to cmp since 24.05
    // lib.optionalAttrs (!stable) {
      cmp = lib.mkIf (!(stable)) {
        enable = true;
        settings = {
          mapping = {
            "<CR>" = "cmp.mapping.confirm({select = false})";
            "<Tab>" = ''cmp.mapping(function(fallback)
                if cmp.visible() then
                  cmp.select_next_item()
                else
                  fallback()
                end
              end
              ,{"i","s"})'';
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
  // lib.optionalAttrs (!stable) {opts = myOptions;}
  // lib.optionalAttrs (stable) {options = myOptions;};
}
