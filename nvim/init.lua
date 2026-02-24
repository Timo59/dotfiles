-- =============================================================================
-- Neovim Configuration for LaTeX Writing
-- =============================================================================
-- Focused on thesis writing with VimTeX, integrates with Skim PDF viewer
-- and custom compilation workflow from pdfLaTeXWithBuild.engine
-- =============================================================================

-- Bootstrap lazy.nvim plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Leader key (before lazy setup)
vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- =============================================================================
-- Plugin Setup
-- =============================================================================
require("lazy").setup({
  -- VimTeX: LaTeX support
  {
    "lervag/vimtex",
    lazy = false,
    init = function()
      -- Use Skim as PDF viewer (supports SyncTeX)
      vim.g.vimtex_view_method = "skim"

      -- Skim settings for forward search
      vim.g.vimtex_view_skim_sync = 1
      vim.g.vimtex_view_skim_activate = 1

      -- Use custom compile script (same as TeXShop engine)
      vim.g.vimtex_compiler_method = "generic"
      vim.g.vimtex_compiler_generic = {
        command = vim.fn.expand("~/.dotfiles/latex-compile.sh"),
      }

      -- Quickfix settings
      vim.g.vimtex_quickfix_mode = 2
      vim.g.vimtex_quickfix_open_on_warning = 0

      -- Don't open quickfix on errors automatically (less intrusive)
      vim.g.vimtex_quickfix_autoclose_after_keystrokes = 3

      -- TOC settings
      vim.g.vimtex_toc_config = {
        split_width = 40,
        show_help = 0,
      }

      -- Subfiles: compile the current file, not the main document
      vim.g.vimtex_subfile_start_local = 1
    end,
  },

  -- Treesitter for better syntax highlighting (C, Python, etc.)
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    ft = { "c", "cpp", "python", "lua", "bash", "json", "yaml", "markdown" },
    config = function()
      local ok, configs = pcall(require, "nvim-treesitter.configs")
      if not ok then return end
      configs.setup({
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<C-space>",
            node_incremental = "<C-space>",
            node_decremental = "<BS>",
          },
        },
      })
    end,
  },

  -- Telescope for fuzzy finding
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local telescope = require("telescope")
      local builtin = require("telescope.builtin")

      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Grep in files" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
    end,
  },

  -- Auto-pairs for brackets
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
  },

  -- Comment.nvim for easy commenting
  {
    "numToStr/Comment.nvim",
    config = true,
  },

  -- Colorscheme (disabled - using built-in for Terminal.app compatibility)

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      require("lualine").setup({
        options = {
          theme = "auto",
          icons_enabled = false,  -- No Nerd Font needed
          component_separators = { left = "|", right = "|" },
          section_separators = { left = "", right = "" },
        },
        sections = {
          lualine_c = {
            { "filename", path = 1 },  -- Show relative path
          },
        },
      })
    end,
  },

  -- Git signs in gutter
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add          = { text = "+" },
          change       = { text = "~" },
          delete       = { text = "_" },
          topdelete    = { text = "-" },
          changedelete = { text = "~" },
        },
      })
    end,
  },

  -- Which-key for keybinding hints
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("which-key").setup({
        icons = {
          mappings = false,  -- No Nerd Font icons
        },
      })
    end,
  },
})

-- =============================================================================
-- General Settings
-- =============================================================================
local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- UI
-- iTerm2: set termguicolors = true and add a truecolor colorscheme plugin, e.g.:
--   { "folke/tokyonight.nvim", config = function() vim.cmd.colorscheme("tokyonight") end }
-- Also remove the colorscheme("slate") line below and the background = "dark" line.
opt.termguicolors = false  -- Terminal.app: false. iTerm2: flip to true (see note above)
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.background = "dark"

-- High contrast colorscheme for Terminal.app
vim.cmd.colorscheme("slate")

-- Split behavior
opt.splitbelow = true
opt.splitright = true

-- Undo/backup
opt.undofile = true
opt.swapfile = false
opt.backup = false

-- Wrapping (important for LaTeX)
opt.wrap = true
opt.linebreak = true  -- Wrap at word boundaries
opt.breakindent = true  -- Indent wrapped lines

-- Spell checking for LaTeX
opt.spell = false  -- Enable with :set spell
opt.spelllang = "en_us"

-- Clipboard
opt.clipboard = "unnamedplus"

-- Update time (for gitgutter, etc.)
opt.updatetime = 250

-- =============================================================================
-- Keymaps
-- =============================================================================
local keymap = vim.keymap.set

-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Buffer navigation
keymap("n", "<S-h>", ":bprevious<CR>", { desc = "Previous buffer", silent = true })
keymap("n", "<S-l>", ":bnext<CR>", { desc = "Next buffer", silent = true })

-- Clear search highlight
keymap("n", "<Esc>", ":nohlsearch<CR>", { silent = true })

-- Better indenting (stay in visual mode)
keymap("v", "<", "<gv")
keymap("v", ">", ">gv")

-- Move lines up/down
keymap("v", "J", ":m '>+1<CR>gv=gv", { silent = true })
keymap("v", "K", ":m '<-2<CR>gv=gv", { silent = true })

-- Keep cursor centered when scrolling
keymap("n", "<C-d>", "<C-d>zz")
keymap("n", "<C-u>", "<C-u>zz")
keymap("n", "n", "nzzzv")
keymap("n", "N", "Nzzzv")

-- Quick save
keymap("n", "<leader>w", ":w<CR>", { desc = "Save file", silent = true })

-- Quick quit
keymap("n", "<leader>q", ":q<CR>", { desc = "Quit", silent = true })

-- Split windows
keymap("n", "<leader>sv", ":vsplit<CR>", { desc = "Split vertical", silent = true })
keymap("n", "<leader>sh", ":split<CR>", { desc = "Split horizontal", silent = true })

-- =============================================================================
-- Auto Commands
-- =============================================================================
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- =============================================================================
-- LaTeX-specific Keymaps (using localleader ",")
-- =============================================================================
local latex_group = augroup("LatexSettings", { clear = true })
autocmd("FileType", {
  group = latex_group,
  pattern = "tex",
  callback = function()
    local opts = { buffer = true }

    -- VimTeX commands with localleader
    keymap("n", "<localleader>ll", "<cmd>VimtexCompile<CR>", vim.tbl_extend("force", opts, { desc = "Compile LaTeX" }))
    keymap("n", "<localleader>lv", "<cmd>VimtexView<CR>", vim.tbl_extend("force", opts, { desc = "View PDF" }))
    keymap("n", "<localleader>lt", "<cmd>VimtexTocToggle<CR>", vim.tbl_extend("force", opts, { desc = "Toggle TOC" }))
    keymap("n", "<localleader>lc", "<cmd>VimtexClean<CR>", vim.tbl_extend("force", opts, { desc = "Clean aux files" }))
    keymap("n", "<localleader>le", "<cmd>VimtexErrors<CR>", vim.tbl_extend("force", opts, { desc = "Show errors" }))
    keymap("n", "<localleader>ls", "<cmd>VimtexStop<CR>", vim.tbl_extend("force", opts, { desc = "Stop compiler" }))
    keymap("n", "<localleader>li", "<cmd>VimtexInfo<CR>", vim.tbl_extend("force", opts, { desc = "VimTeX info" }))

    -- Enable spell checking for LaTeX files
    vim.opt_local.spell = true

    -- Soft wrap for LaTeX (don't break in middle of words)
    vim.opt_local.textwidth = 0
    vim.opt_local.wrapmargin = 0
  end,
})

-- Highlight on yank
local yank_group = augroup("YankHighlight", { clear = true })
autocmd("TextYankPost", {
  group = yank_group,
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- Return to last edit position
autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Resize splits when window is resized
autocmd("VimResized", {
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})
