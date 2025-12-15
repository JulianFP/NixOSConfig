{ pkgs, lib, ... }:

{
  imports = [
    ./neovim-basic.nix
  ];

  programs.nixvim = {
    #override colorscheme
    colorschemes.onedark.enable = lib.mkForce false;

    globals = {
      #for vimtex
      vimtex_view_general_viewer = "okular";
      vimtex_view_general_options = "--unique file:@pdf\#src:@line@tex";

      # for custom build and run commands
      dir = "%:p:h";
      folder = "%:p:h:t";
      file = "%:t";
    };

    # custom build and run commands (they depend on alacritty and a custom bash script)
    userCommands = {
      "CreateCMakeFile" = {
        command = "execute '!bash ~/.config/nvim/createCMakeFile.sh ' . g:folder . ' ' . g:file";
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
        command = "execute ':silent !alacritty --hold -e ~/.systemScripts/launch.sh ' . g:dir . '/buildDebug/' . g:folder";
        bang = true;
        desc = "runs debug binary of the current project (BuildDebug has to run first)";
      };
      "RunRelease" = {
        command = "execute ':silent !alacritty --hold -e ~/.systemScripts/launch.sh ' . g:dir . '/buildRelease/' . g:folder";
        bang = true;
        desc = "runs release binary of the current project (BuildRelease has to run first)";
      };
    };

    keymaps = [
      #mode = "": for normal,visual,select,operator-pending modes (map)
      #mode = "n": for normal mode
      #mode = "i": for insert mode

      #lsp related keymaps are defined in commonNeovim.nix under plugins.lsp

      # set window navigation keys
      {
        mode = "";
        key = "<c-j>";
        action = "<c-w>j";
      }
      {
        mode = "";
        key = "<c-k>";
        action = "<c-w>k";
      }
      {
        mode = "";
        key = "<c-l>";
        action = "<c-w>l";
      }
      {
        mode = "";
        key = "<c-h>";
        action = "<c-w>h";
      }

      #for luasnips
      {
        mode = [
          ""
          "i"
        ];
        key = "<c-w>";
        action = "<cmd>lua require('luasnip').jump(1)<Cr>";
        options.silent = true;
      }
      {
        mode = [
          ""
          "i"
        ];
        key = "<c-b>";
        action = "<cmd>lua require('luasnip').jump(-1)<Cr>";
        options.silent = true;
      }
      {
        mode = [
          ""
          "i"
        ];
        key = "<c-n>";
        action = "luasnip#choice_active() ? '<Plug>luasnip-next-choice'";
        options.silent = true;
      }

      #for custom build and run
      {
        mode = "n";
        key = "<Leader>bc";
        action = ":CreateCMakeFile<CR>";
      }
      {
        mode = "n";
        key = "<Leader>bd";
        action = ":BuildDebug<CR>";
      }
      {
        mode = "n";
        key = "<Leader>br";
        action = ":BuildRelease<CR>";
      }
      {
        mode = "n";
        key = "<Leader>rd";
        action = ":RunDebug<CR>";
      }
      {
        mode = "n";
        key = "<Leader>rr";
        action = ":RunRelease<CR>";
      }

      #for dap (debugging)
      {
        mode = "n";
        key = "<LocalLeader>c";
        action = ":DapContinue<CR>";
      }
      {
        mode = "n";
        key = "<LocalLeader>n";
        action = ":DapStepOver<CR>";
      }
      {
        mode = "n";
        key = "<LocalLeader>s";
        action = ":DapStepInto<CR>";
      }
      {
        mode = "n";
        key = "<LocalLeader>f";
        action = ":DapStepOut<CR>";
      }
      {
        mode = "n";
        key = "<LocalLeader>b";
        action = ":DapToggleBreakpoint<CR>";
      }
      {
        mode = "n";
        key = "<LocalLeader>q";
        action = ":DapTerminate<CR>";
      }

      #telescope
      {
        mode = "";
        key = "<LocalLeader>t";
        action = ":Telescope file_browser<CR>";
      }

      #for typst
      {
        mode = "";
        key = "<LocalLeader>tt";
        action = ":TypstPreviewToggle<CR>";
      }
      {
        mode = "";
        key = "<LocalLeader>tc";
        action = ":TypstPreviewSyncCursor<CR>";
      }
    ];

    #change lsp icons from default "E,W,H,I" to custom nerdfont icons
    #not in commonNeovim since this requires the nerdfont font to be used in terminal
    extraConfigLua = ''
      local signs = { Error = "", Warn = "", Hint = "", Info = "" }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      end
    '';

    plugins = {
      #install all treesitter grammars (as by default)
      treesitter.grammarPackages = pkgs.vimPlugins.nvim-treesitter.passthru.allGrammars;

      #LaTeX support
      vimtex = {
        enable = true;
        texlivePackage = pkgs.texlive.combined.scheme-full;
      };

      #file browser/switcher
      telescope = {
        enable = true;
        settings.defaults = {
          initial_mode = "normal";
          mappings.n = {
            "l" = "select_default";
          };
        };
        extensions.file-browser = {
          enable = true;
          settings.mappings."n" = {
            "h" = "require('telescope._extensions.file_browser.actions').goto_parent_dir";
          };
        };
      };

      #theme for status bar at bottom
      lualine.settings.options.theme = lib.mkForce "auto";

      web-devicons.enable = true;

      #snippet engine
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
              "java"
              "typescript"
              "svelte"
            ];
          }
          {
            paths = ./customSnippets;
          }
        ];
      };
      #collection of default snippets
      friendly-snippets.enable = true;

      #error highlighting and autocomplete (different language servers + luasnip config)
      lsp = {
        servers = {
          bashls.enable = true; # lsp server for Bash
          clangd.enable = true; # lsp server for C/C++
          pyright.enable = true; # lsp server for Python
          nil_ls.enable = true; # lsp server for Nix
          texlab.enable = true; # lsp Server for LaTeX
          java_language_server.enable = true; # lsp Server for Java
          ts_ls.enable = true; # lsp server for Typescript
          svelte.enable = true; # lsp server for Svelte (Javascript Framework)
          rust_analyzer = {
            # lsp server for Rust
            enable = true;
            installRustc = true;
            installCargo = true;
          };
          tinymist.enable = true; # lsp server for Typst
        };
      };
      cmp.settings = {
        snippet.expand = ''function(args) require('luasnip').lsp_expand(args.body) end'';
        sources = [
          { name = "nvim_lsp"; }
          { name = "luasnip"; } # For luasnip users.
          { name = "path"; }
          { name = "buffer"; }
          { name = "nvim_lsp_signature_help"; }
        ];
      };
      cmp-nvim-lsp-signature-help.enable = true; # shows signature of functions etc. while typing

      #debugging
      dap = {
        enable = true;
        adapters.servers."codelldb" = {
          port = 13000;
          executable = {
            command = "${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb";
            args = [
              "--port"
              "13000"
            ];
          };
        };
        configurations."cpp" = [
          {
            name = "Launch file";
            type = "codelldb";
            request = "launch";
            program = "\${dir} .. '/buildDebug/' .. \${folder}";
            stopOnEntry = false;
          }
        ];
        signs.dapBreakpoint.text = "🛑";
      };
      dap-ui.enable = true;

      #typst
      typst-preview.enable = true;
    };
    extraConfigLuaPost = ''
      require("ibl").setup()

      local dap, dapui =require("dap"),require("dapui")
      dap.configurations.cpp = {
        {
          name = "Launch file",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
          end,
          cwd = ''\'''${workspaceFolder}',
          stopOnEntry = false,
        },
      }
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    '';
  };

  xdg.configFile = {
    "nvim/createCMakeFile.sh" = {
      source = ./scripts/createCMakeFile.sh;
      executable = true;
    };
  };
}
