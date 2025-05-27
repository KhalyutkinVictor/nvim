-- init.lua
-- Lazy.nvim setup
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- finding phpcs files
local phpcs_conf_file = vim.fn.stdpath("data") .. "/kh_phpcs_conf.json"

local function load_phpcs_conf()
  local json_decode = vim.fn.json_decode

  local file = phpcs_conf_file
  local f = io.open(file, "r")
  if f then
    local content = f:read("*a")
    f:close()
    local decoded = json_decode(content)
    return decoded or {}
  end
  return {}
end

local function save_phpcs_conf(conf)
  local json_encode = vim.fn.json_encode
  local json_str = json_encode(conf)

  local file = io.open(phpcs_conf_file, "w")
  if file then
    file:write(json_str)
    file:close()
  else
    print("Error: Could not open file for writing")
  end
end

local function set_phpcs(ruleset)
  vim.g.ale_php_phpcbf_standard = vim.fn.getcwd() .. "/" .. ruleset
  vim.g.ale_php_phpcs_standard = vim.fn.getcwd() .. "/" .. ruleset
end

local function save_phpcs(ruleset)
  local conf = load_phpcs_conf()
  conf[vim.fn.getcwd()] = ruleset
  save_phpcs_conf(conf)
end

local function set_and_save_phpcs(ruleset)
  set_phpcs(ruleset)
  save_phpcs(ruleset)
end

local function ask_for_phpcs_file()
  vim.ui.input({ prompt = "Enter phpcs ruleset file path (or enter \"e\" to skip this): " }, function(input)
    if input and vim.fn.filereadable(input) == 1 then
        set_and_save_phpcs(input)
    elseif not input or input == 'e' or input == 'exit' then
        set_and_save_phpcs('e')
        return
    else
        ask_for_phpcs_file()
    end
  end)
end

local function load_phpcs_ruleset()
  local conf = load_phpcs_conf()
  return conf[vim.fn.getcwd()]
end

local function find_phpcs_ruleset()
  local saved_ruleset = load_phpcs_ruleset()
  if saved_ruleset ~= nil then
    if saved_ruleset == 'e' then
      return
    end
    set_phpcs(saved_ruleset)
    return
  end

  local files_to_try = {
    "phpcs.ruleset.xml",
    "phpcs.xml",
  }

  for _, file in ipairs(files_to_try) do
    if vim.fn.filereadable(file) == 1 then
      set_and_save_phpcs(file)
      return
    end
  end

  ask_for_phpcs_file()
end
vim.api.nvim_create_user_command("ALESetPhpcsRuleset", ask_for_phpcs_file, {})


require("lazy").setup({
  -- Color scheme
  { "morhetz/gruvbox" },
  -- LSP configuration
  {
    "neovim/nvim-lspconfig",
    dependencies = { "hrsh7th/cmp-nvim-lsp", "ray-x/lsp_signature.nvim", },
    config = function()
      local lsp_signature = require("lsp_signature")
      local custom_on_attach = function(client, bufnr)
        on_attach(client, bufnr) -- keep your existing on_attach
        lsp_signature.on_attach({}, bufnr) -- add signature help
      end

      require'lspconfig'.phpactor.setup{
        on_attach = custom_on_attach,
        init_options = {
          ["language_server_completion.trim_leading_dollar"] = true,
          ["language_server_phpstan.enabled"] = true,
          ["language_server_psalm.enabled"] = false,
        }
      }
    end,
  },
  -- Common utilities
  { "nvim-lua/plenary.nvim" },
  -- Autocompletion plugin
  {
    "hrsh7th/nvim-cmp",
    config = function()
      local cmp = require("cmp")
      local lsp = require("cmp_nvim_lsp")
      cmp.setup({
        mapping = {
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            else
              fallback()
            end
          end, { "i", "s" }),
        },
        sources = {
          { name = "nvim_lsp" },
        },
      })

      local capabilities = lsp.default_capabilities()
      -- php ls
      require("lspconfig").phpactor.setup({
        capabilities = capabilities,
      })
      -- js ts ls
      require("lspconfig").ts_ls.setup({
        capabilities = capabilities,
      })
    end,
  },
  -- VSCode-like pictograms
  { "onsails/lspkind-nvim" },
  -- Snippets plugin
  { "L3MON4D3/LuaSnip" },
  {
      "dense-analysis/ale",
      config = function()
        find_phpcs_ruleset()
      end
  },
  -- Forked version of ALE temporarily
  --{ "kevinquinnyo/ale", branch = "phpstan-memory-limit-option" }, -- Corrected URL

  -- Run tests in Vim
  { "janko/vim-test" },
  -- PHP code introspection and more
  { "phpactor/phpactor", run = "composer install --no-dev -n" },
  -- Syntax highlighting
  { "nvim-treesitter/nvim-treesitter" },
  -- Statusline plugin
  { "feline-nvim/feline.nvim" },
  -- Fuzzy file finder
  { "ctrlpvim/ctrlp.vim" },

-- copilot plugin
--  { "github/copilot.vim", url = "git@github.com:github/copilot.vim.git" },

  -- NvimTree plugin
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        view = {
          width = 50,
        },
      })
    end,
    cmd = "NvimTreeToggle",
  },

  -- cyberdream theme
  {
    "scottmckendry/cyberdream.nvim",
    lazy = false,
    priority = 1000,
  },

  -- buffer manager plugin
  {
    "j-morano/buffer_manager.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>bm", "<cmd>lua require('buffer_manager.ui').toggle_quick_menu()<CR>", desc = "Buffer Manager" },
    },
    config = function()
      require("buffer_manager").setup({})
    end,
  },
  -- code screenshots
  {
    "SergioRibera/codeshot.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("codeshot").setup({
        copy = "%c | wl-copy"
      })
    end,
  },
  -- telescope (search plugin)
  { 'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('telescope').setup{
        defaults = {
          vimgrep_arguments = {
            'rg',
            '--color=never',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
            '--smart-case',
            '--glob',
            '!.git/',
            '--glob',
            '!node_modules/',
            '--glob',
            '!vendor/',
            '--glob',
            '!.phpstorm/',
            '--glob',
            '!*/cache/*'
          }
        }
      }
    end
  },
  -- autopairs for () [] {} <>
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("nvim-autopairs").setup({
        check_ts = true, -- enable Tree-sitter support
      })
    end,
  },
  -- peek preview like in vs code
  {
    'dnlhc/glance.nvim',
    cmd = 'Glance'
  },
  -- completions for method signatures
  {
    "ray-x/lsp_signature.nvim",
    event = "InsertEnter",
    opts = {
      bind = true
    },
  },
  -- color schemes manager
  {
    "vague2k/huez.nvim",
    -- if you want registry related features, uncomment this
    import = "huez-manager.import",
    branch = "stable",
    event = "UIEnter",
    config = function()
        require("huez").setup({})
    end,
  },
  -- gitsigns git integration plugin
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require('gitsigns').setup({
          current_line_blame = true,
          current_line_blame_opts = {
            delay = 300,
          },
          signcolumn = true,
      })
    end
  },
  -- incremental rename plugin
  {
    "smjonas/inc-rename.nvim",
    config = function()
      require("inc_rename").setup()
    end,
  },
  -- database manager
  {
    "kndndrj/nvim-dbee",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    build = function()
      -- Install tries to automatically detect the install method.
      -- if it fails, try calling it with one of these parameters:
      --    "curl", "wget", "bitsadmin", "go"
      require("dbee").install()
    end,
    config = function()
      require("dbee").setup(--[[optional config]])
    end,
  },
  -- mason
  {
    "williamboman/mason.nvim", config = function()
      require("mason").setup()
    end
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        automatic_installation = true,
      })
    end
  },
  { "jose-elias-alvarez/typescript.nvim" },
})

-- Check if     Composer is installed
local function check_composer()
  local handle = io.popen("composer --version")
  local result = handle:read("*a")
  handle:close()
  if not result:match("Composer version") then
    vim.api.nvim_err_writeln("Warning: Composer is not installed. PHPActor might not work correctly.")
  end
end

-- Call the check_composer function
check_composer()

-- General settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

vim.opt.smartindent = true -- Smart indentation
vim.opt.autoindent = true -- Auto-indent new lines
vim.opt.hidden = true -- Allow switching buffers without saving

vim.cmd([[
  augroup PhpIndentFix
    autocmd!
    autocmd FileType php setlocal autoindent smartindent indentexpr=
  augroup END
]])

-- cycle through buffers with tab and shift-tab
vim.api.nvim_set_keymap('n', '<Tab>', ':bnext<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<S-Tab>', ':bprev<CR>', { noremap = true })

-- i hold shift for too long when doing wq, "fix" it
vim.api.nvim_set_keymap('n', 'W', ':w<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', 'Wq', ':wq<CR>', { noremap = true })

-- Enable true color support
vim.opt.termguicolors = true

-- ALE configuration
vim.g.ale_php_phpcs_executable = 'phpcs'
vim.g.ale_php_phpstan_executable = 'phpstan'
vim.g.ale_php_phpstan_memory_limit = '-1'
vim.g.ale_linters = { php = {'phpcs', 'phpstan'} }
vim.g.ale_fixers = {
    ['*'] = { 'remove_trailing_lines', 'trim_whitespace' },
    php = { 'phpcbf' },
}
vim.g.ale_fix_on_save = 1
vim.g.ale_php_phpcbf_executable = 'phpcbf'


-- show warning info on hover
vim.o.updatetime = 300
vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    if vim.fn.mode() ~= "n" then
      return
    end
    vim.diagnostic.open_float(0, { focusable = false, scope = "line", border = "rounded", max_height = 20 })
  end,
})

-- Shortcut for showing full ALE lint error message
vim.api.nvim_set_keymap('n', '<leader>ee', ':ALEDetail<CR>', { noremap = true, silent = true })

-- Edit this file
vim.api.nvim_set_keymap('n', '<Leader>ev', ':e $MYVIMRC<CR>', { noremap = true, silent = true })

-- Edit .zshrc file
vim.api.nvim_set_keymap('n', '<Leader>ez', ':e ~/.zshrc<CR>', { noremap = true, silent = true })

-- PHPActor key mappings
vim.api.nvim_set_keymap('n', '<Leader>o', ':PhpactorGotoDefinition<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>u', ':PhpactorImportClass<CR>', { noremap = true, silent = true })

-- CtrlP key mappings
--vim.g.ctrlp_map = '<c-f>'
-- Manually set CtrlP key mapping
vim.api.nvim_set_keymap('n', '<C-f>', ':CtrlP<CR>', { noremap = true, silent = true })
vim.g.ctrlp_cmd = 'CtrlP'
vim.g.ctrlp_max_depth = 100
vim.g.ctrlp_cache_dir = vim.fn.expand("$HOME") .. "/.cache/ctrlp"
vim.g.ctrlp_custom_ignore = '\\v[\\/](vendor|node_modules|\\.git)[\\/]'

if vim.fn.executable("ag") == 1 then
  vim.g.ctrlp_user_command = "ag %s -l --nocolor -g \"\""
end

-- Feline configuration
require('feline').setup()

-- Treesitter configuration
require'nvim-treesitter.configs'.setup {
  ensure_installed = { "c", "python", "javascript", "html", "css", "php", "go", "rust", "markdown", "markdown_inline" },
  sync_install = false,
  auto_install = true,
  highlight = {
    enable = true,
    disable = { },
    additional_vim_regex_highlighting = false,
  },
}



-- cyberdream theme config
require("cyberdream").setup({
    -- Set light or dark variant
    variant = "default", -- use "light" for the light variant. Also accepts "auto" to set dark or light colors based on the current value of `vim.o.background`

    -- Enable transparent background
    transparent = true,

    -- Reduce the overall saturation of colours for a more muted look
    saturation = 1, -- accepts a value between 0 and 1. 0 will be fully desaturated (greyscale) and 1 will be the full color (default)

    -- Enable italics comments
    italic_comments = true,

    -- Replace all fillchars with ' ' for the ultimate clean look
    hide_fillchars = false,

    -- Apply a modern borderless look to pickers like Telescope, Snacks Picker & Fzf-Lua
    borderless_pickers = false,

    -- Set terminal colors used in `:terminal`
    terminal_colors = true,

    -- Improve start up time by caching highlights. Generate cache with :CyberdreamBuildCache and clear with :CyberdreamClearCache
    cache = false,
})

-- Misc
vim.cmd("iabbrev dst declare(strict_types=1);") -- type dst to add declare(strict_types=1);

vim.opt.relativenumber = true
vim.opt.number = true

-- auto insert -> for methods
vim.api.nvim_create_autocmd("FileType", {
  pattern = "php",
  callback = function()
    function _G.smart_arrow()
      local col = vim.fn.col('.') - 1
      local current_line = vim.fn.getline('.')

      local lookup_char = '.';

      -- Check if current line is empty or only whitespace
      if current_line:match('^%s*$') then
        -- Move to the previous line to check
        local prev_line = vim.fn.getline(vim.fn.line('.') - 1)
        lookup_char = prev_line:sub(-1)
      else
        lookup_char = current_line:sub(col, col)
      end

      if lookup_char:match('%w') or lookup_char == '$' or lookup_char:match('[%)%]%)]') then
        return '->'
      end

      return '-'
    end

    vim.api.nvim_set_keymap('i', '-', 'v:lua.smart_arrow()', {expr = true, noremap = true})
  end
})

-- NvimTree go to current file
vim.keymap.set('n', '<leader>f', function()
  local api = require("nvim-tree.api")
  if not api.tree.is_visible() then
    api.tree.toggle()  -- Open NvimTree if it's not open
  end
  api.tree.find_file()  -- Focus on the current file
end, { noremap = true, silent = true })

-- Go to definition via lsp command
vim.api.nvim_create_user_command('GoDef', function()
  vim.lsp.buf.definition()
end, {})
