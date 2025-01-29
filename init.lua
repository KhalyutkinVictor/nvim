-- init.lua
-- Check if Composer is installed
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

-- Bootstrap packer.nvim if it's not already installed
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

-- Load plugins
require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'         -- Packer can manage itself
  use 'morhetz/gruvbox'                -- Color scheme
  use 'neovim/nvim-lspconfig'          -- LSP configuration
  use 'nvim-lua/plenary.nvim'          -- Common utilities
  use 'hrsh7th/nvim-cmp'               -- Autocompletion plugin
  use 'onsails/lspkind-nvim'           -- VSCode-like pictograms
  use 'L3MON4D3/LuaSnip'               -- Snippets plugin
  --use 'dense-analysis/ale'             -- Asynchronous Lint Engine
  -- use our forked version of ale to fix phpstan memory-limit option it's at /Users/kevin/dev/ale
  use {'~/dev/ale'}                     -- Forked version temporarily
  use 'janko/vim-test'                 -- Run tests in Vim
  use {
  'phpactor/phpactor',
    run = 'composer install --no-dev -n'
  } -- PHP code introspection and more
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate'
  } -- syntax highlighting
  use 'preservim/nerdtree'             -- File tree explorer
  use 'feline-nvim/feline.nvim'        -- Statusline plugin
  use 'ctrlpvim/ctrlp.vim'             -- Fuzzy file finder

  -- Automatically set up your configuration after cloning packer.nvim
  if packer_bootstrap then
    require('packer').sync()
  end
end)

-- General settings
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

vim.opt.smartindent = true -- Smart indentation
vim.opt.autoindent = true -- Auto-indent new lines
vim.opt.hidden = true -- Allow switching buffers without saving

-- cycle through buffers with tab and shift-tab
vim.api.nvim_set_keymap('n', '<Tab>', ':bnext<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<S-Tab>', ':bprev<CR>', { noremap = true })

-- i hold shift for too long when doing wq, "fix" it
vim.api.nvim_set_keymap('n', 'W', ':w<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', 'Wq', ':wq<CR>', { noremap = true })

-- hardmode
--vim.opt.hardmode = true

-- Enable true color support
vim.opt.termguicolors = true

-- Set color scheme
vim.cmd('colorscheme gruvbox')
vim.opt.background = "dark"

-- ALE configuration
vim.g.ale_php_phpcs_executable = 'phpcs'
vim.g.ale_php_phpstan_executable = 'phpstan'
-- todo: we can't use this until https://github.com/dense-analysis/ale/pull/4900 lands
vim.g.ale_php_phpstan_memory_limit = '-1'
--vim.g.ale_php_phpmd_executable = 'phpmd'
--
vim.g.ale_linters = { php = {'phpcs', 'phpstan'} }
--vim.g.ale_fixers = { php = {'php_cs_fixer'} }

-- Use a custom phpcbf wrapper script
vim.g.ale_php_phpcbf_executable = '/Users/kevin/bin/phpcbf-wrapper.sh'

-- Declare it as 'use global' even though it's a custom path
--vim.g.ale_php_phpcbf_use_global = 1

-- Define ALE fixers
vim.g.ale_fixers = {
    ['*'] = { 'remove_trailing_lines', 'trim_whitespace' },
    php = { 'phpcbf' },
}

-- Enable auto-fixing on save
vim.g.ale_fix_on_save = 1

-- Shortcut for showing full ALE lint error message
vim.api.nvim_set_keymap('n', '<leader>ee', ':ALEDetail<CR>', { noremap = true, silent = true })

-- Edit this file
vim.api.nvim_set_keymap('n', '<Leader>ev', ':e $MYVIMRC<CR>', { noremap = true, silent = true })

-- Edit .zshrc file
vim.api.nvim_set_keymap('n', '<Leader>ez', ':e ~/.zshrc<CR>', { noremap = true, silent = true })

-- PHPActor key mappings
vim.api.nvim_set_keymap('n', '<Leader>o', ':PhpactorGotoDefinition<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>u', ':PhpactorUseAdd<CR>', { noremap = true, silent = true })

-- CtrlP key mappings
vim.g.ctrlp_map = '<c-f>'
vim.g.ctrlp_cmd = 'CtrlP'
--vim.g.ctrlp_custom_ignore = {
--  dir = { '.git', 'node_modules', 'dist' },
--  file = { '*.min.js', '*.min.css' }
--}
vim.g.ctrlp_max_depth = 50
vim.g.ctrlp_cache_dir = vim.fn.expand("$HOME") .. "/.cache/ctrlp"

if vim.fn.executable("ag") == 1 then
  vim.g.ctrlp_user_command = "ag %s -l --nocolor -g \"\""
end


-- Feline configuration
require('feline').setup()

-- Treesitter configuration
require'nvim-treesitter.configs'.setup {
  -- A list of parser names, or "all"
  ensure_installed = { "c", "lua", "python", "javascript", "html", "css", "php", "go", "rust" },

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- Automatically install missing parsers when entering buffer
  auto_install = true,

  highlight = {
    -- `false` will disable the whole extension
    enable = true,

    -- list of language that will be disabled
    disable = { },

    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    additional_vim_regex_highlighting = false,
  },
}

-- Misc
vim.cmd("iabbrev dst declare(strict_types=1);") -- type dst to add declare(strict_types=1);
