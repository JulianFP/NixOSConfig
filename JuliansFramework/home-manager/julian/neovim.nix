{ pkgs, ... }:

{
  programs.nixvim = {
    globals = {
      #for vimtex
      vimtex_view_general_viewer = "okular";
      vimtex_view_general_options = "--unique file:@pdf\#src:@line@tex";

      # for custom build and run commands
      dir = "%:p:h";
      folder = "%:p:h:t";
      file = "%:t";
    };

    #clipboard support
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
    ];

    plugins = {
      #LaTeX support
      vimtex.enable = true;

      #file browser/switcher
      telescope = {
        enable = true;
        defaults = {
          initial_mode = "normal";
          mappings.n = {
            "l" = "select_default";
          };
        };
        extensions.file_browser = {
          enable = true;
          mappings = {
            "n" = {
              "h" = "goto_parent_dir";
            };
          };
        };
      };

      #theme for status bar at bottom
      lualine.theme = "gruvbox";

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
            ];
          }
	      ];
      };

      #error highlighting and autocomplete (different language servers + luasnip config)
      lsp = {
        servers = {
          bashls.enable = true;	#lsp server for Bash
          clangd.enable = true; #lsp server for C/C++
          pyright.enable = true;#lsp server for Python
          nil_ls.enable = true;	#lsp server for Nix
          texlab.enable = true; #lsp Server for LaTeX
          java-language-server.enable = true; #lsp Server for Java
          svelte.enable = true; #lsp server for Svelte (Javascript Framework)
        };
      };
      nvim-cmp = {
        snippet.expand = "luasnip";
        sources = [
          { name = "nvim_lsp"; }
          { name = "luasnip"; } #For luasnip users.
          { name = "path"; }
          { name = "buffer"; }
        ];
      };

      #debugging 
      dap = {
        enable = true; 
        adapters.servers."codelldb" = {
          port = 13000;
          executable = {
            command = "${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb";
            args = [ "--port" "13000" ];
          };
        };
        configurations."cpp" = [{
          name = "Launch file";
          type = "codelldb";
          request = "launch";
          program = "\${dir} .. '/buildDebug/' .. \${folder}";
          stopOnEntry = false;
        }];
        extensions.dap-ui.enable = true;
        signs.dapBreakpoint.text = "🛑";
      };
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

    #collection of default snippets
    extraPlugins = with pkgs.vimPlugins; [
      friendly-snippets
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
