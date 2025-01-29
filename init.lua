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

require("lazy").setup({
  -- Color scheme
  { "morhetz/gruvbox" },
  -- LSP configuration
  { "neovim/nvim-lspconfig" },
  -- Common utilities
  { "nvim-lua/plenary.nvim" },
  -- Autocompletion plugin
  { "hrsh7th/nvim-cmp" },
  -- VSCode-like pictograms
  { "onsails/lspkind-nvim" },
  -- Snippets plugin
  { "L3MON4D3/LuaSnip" },
  { "dense-analysis/ale" },
  -- Forked version of ALE temporarily
  { "kevinquinnyo/ale", branch = "phpstan-memory-limit-option" }, -- Corrected URL

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
  { "github/copilot.vim", url = "git@github.com:github/copilot.vim.git" }
})

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

-- Enable true color support
vim.opt.termguicolors = true

-- Set color scheme
vim.cmd('colorscheme gruvbox')
vim.opt.background = "dark"

-- ALE configuration
vim.g.ale_php_phpcs_executable = 'phpcs'
vim.g.ale_php_phpstan_executable = 'phpstan'
vim.g.ale_php_phpstan_memory_limit = '-1'
vim.g.ale_linters = { php = {'php', 'phpcs', 'phpstan'} }
vim.g.ale_fixers = {
    ['*'] = { 'remove_trailing_lines', 'trim_whitespace' },
    php = { 'phpcbf' },
}
vim.g.ale_fix_on_save = 1
vim.g.ale_php_phpcbf_executable = '/Users/kevin/bin/phpcbf-wrapper.sh'

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
--vim.g.ctrlp_map = '<c-f>'
-- Manually set CtrlP key mapping
vim.api.nvim_set_keymap('n', '<C-f>', ':CtrlP<CR>', { noremap = true, silent = true })
vim.g.ctrlp_cmd = 'CtrlP'
vim.g.ctrlp_max_depth = 50
vim.g.ctrlp_cache_dir = vim.fn.expand("$HOME") .. "/.cache/ctrlp"


if vim.fn.executable("ag") == 1 then
  vim.g.ctrlp_user_command = "ag %s -l --nocolor -g \"\""
end

-- Feline configuration
require('feline').setup()

-- Treesitter configuration
require'nvim-treesitter.configs'.setup {
  ensure_installed = { "c", "python", "javascript", "html", "css", "php", "go", "rust" },
  sync_install = false,
  auto_install = true,
  highlight = {
    enable = true,
    disable = { },
    additional_vim_regex_highlighting = false,
  },
}

-- Misc
vim.cmd("iabbrev dst declare(strict_types=1);") -- type dst to add declare(strict_types=1);
