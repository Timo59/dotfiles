# Neovim + LaTeX + tmux Tutorial

This tutorial guides you through the neovim-based LaTeX writing workflow.

## Quick Start

```bash
# 1. Install Skim (if not already installed)
brew install --cask skim

# 2. Symlink configs (if not done via setup.sh)
ln -sf ~/.dotfiles/nvim ~/.config/nvim
ln -sf ~/.dotfiles/tmux.conf ~/.tmux.conf

# 3. Open neovim (plugins install automatically on first launch)
nvim

# 4. Start tmux
tmux
```

## First Launch

When you first open neovim, the plugin manager (lazy.nvim) will automatically:
1. Clone itself
2. Install all configured plugins
3. Download treesitter parsers

This takes about 30 seconds. You'll see a progress window.

## tmux Basics

### Starting tmux

```bash
tmux                    # Start new session
tmux new -s thesis      # Start named session
tmux attach -t thesis   # Reattach to session
tmux ls                 # List sessions
```

### Key Bindings (prefix = Ctrl-a)

| Keys | Action |
|------|--------|
| `C-a |` | Split vertically |
| `C-a -` | Split horizontally |
| `C-a h/j/k/l` | Navigate panes (vim keys) |
| `C-a H/J/K/L` | Resize panes |
| `C-a c` | New window |
| `M-h / M-l` | Previous/next window (Alt+h/l) |
| `M-1` to `M-5` | Jump to window 1-5 |
| `C-a x` | Kill pane |
| `C-a Tab` | Toggle last window |
| `C-a r` | Reload config |

### Preset Layouts

| Keys | Layout |
|------|--------|
| `C-a E` | Editor + terminal (70/30 split) |
| `C-a T` | Editor + two terminals |

### Copy Mode

| Keys | Action |
|------|--------|
| `C-a [` | Enter copy mode |
| `v` | Start selection |
| `y` | Copy to clipboard |
| `C-a p` | Paste |

## Neovim Basics

### Leader Keys

- **Leader**: `Space` (for general commands)
- **LocalLeader**: `,` (for filetype-specific commands like LaTeX)

### General Keymaps

| Keys | Action |
|------|--------|
| `Space w` | Save file |
| `Space q` | Quit |
| `Space sv` | Split vertical |
| `Space sh` | Split horizontal |
| `Ctrl-h/j/k/l` | Navigate windows |
| `Shift-h/l` | Previous/next buffer |
| `Esc` | Clear search highlight |

### Telescope (Fuzzy Finder)

| Keys | Action |
|------|--------|
| `Space ff` | Find files |
| `Space fg` | Grep in files |
| `Space fb` | Find buffers |
| `Space fh` | Search help |

## LaTeX Workflow

### VimTeX Keymaps (in .tex files)

All LaTeX commands use LocalLeader (`,`):

| Keys | Action |
|------|--------|
| `,ll` | Compile LaTeX (toggle continuous) |
| `,lv` | View PDF in Skim |
| `,lt` | Toggle table of contents |
| `,lc` | Clean auxiliary files |
| `,le` | Show errors |
| `,ls` | Stop compiler |
| `,li` | Show VimTeX info |

### Typical Session

```bash
# 1. Start tmux with thesis layout
tmux new -s thesis
# Press C-a E for editor + terminal layout

# 2. Open your thesis
nvim ~/path/to/thesis/main.tex

# 3. Start continuous compilation
,ll

# 4. View PDF (opens Skim)
,lv

# 5. Edit - PDF updates automatically on save
```

### Forward/Inverse Search (SyncTeX)

- **Forward search** (neovim → PDF): `,lv` jumps to current position in Skim
- **Inverse search** (PDF → neovim): Shift+Cmd+Click in Skim jumps to source

#### Configure Skim for Inverse Search

1. Open Skim → Preferences → Sync
2. Set Preset to "Custom"
3. Command: `nvim`
4. Arguments: `--headless -c "VimtexInverseSearch %line '%file'"`

Alternative: Use the terminal for inverse search:
1. Preset: Custom
2. Command: `/opt/homebrew/bin/nvim`
3. Arguments: `+%line "%file"`

### Working with .bib Files

Open your .tex and .bib side by side:

```vim
:vsplit path/to/references.bib
```

Or use Telescope to quickly find and open:
```
Space ff → type "bib" → Enter
```

## Spell Checking

Spell checking is enabled by default in .tex files.

| Keys | Action |
|------|--------|
| `]s` | Next misspelled word |
| `[s` | Previous misspelled word |
| `z=` | Suggest corrections |
| `zg` | Add word to dictionary |
| `zw` | Mark word as wrong |

Toggle spell checking: `:set spell!`

## Useful Commands

```vim
:VimtexInfo         " Show VimTeX status
:VimtexTocOpen      " Open table of contents
:VimtexCountWords   " Count words in document
:checkhealth        " Check neovim health
:Lazy               " Open plugin manager
:Lazy update        " Update plugins
```

## Troubleshooting

### Plugins not installing

```vim
:Lazy install
```

### Compilation not working

1. Check VimTeX status: `:VimtexInfo`
2. Check compile script: `:!~/.dotfiles/latex-compile.sh %`
3. View errors: `,le`

### PDF not opening in Skim

```bash
# Verify Skim is installed
ls /Applications/Skim.app

# Test manually
open -a Skim your-file.pdf
```

### Colors look wrong in tmux

Make sure your terminal supports true color. The config is set up for iTerm2 and Terminal.app.

## File Locations

| File | Purpose |
|------|---------|
| `~/.config/nvim/` | Neovim config (symlink to dotfiles) |
| `~/.tmux.conf` | tmux config (symlink to dotfiles) |
| `~/.dotfiles/nvim/init.lua` | Main neovim config |
| `~/.dotfiles/tmux.conf` | tmux config source |
| `~/.dotfiles/latex-compile.sh` | LaTeX build script |
| `~/.local/share/nvim/` | Neovim data (plugins, undo, etc.) |

## Going Back to TeXShop

If you need to fall back to TeXShop:
1. Just open your .tex file in TeXShop as before
2. Both use the same `.build` directory for auxiliary files
3. The PDF stays in the source folder either way

Your workflow is compatible - you can switch freely between editors.
