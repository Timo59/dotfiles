# Taps
# tap 'stripe/stripe-cli'	-- payment infrastructure for the internet

# -----------------------------------------------------------------------------
# Scope policy
# -----------------------------------------------------------------------------
# This file declares the *machine baseline*: tools that are useful outside any
# single project (shell, editor, git, LaTeX, VPN).
#
# Library dependencies of a specific project (boost, eigen, nlohmann-json, ...)
# deliberately do NOT belong here. They go into that project's flake.nix, so
# the project is self-contained and reproducible on any machine — see
# templates/flake.nix. Installing them globally is what caused the two machines
# to drift in the first place.
# -----------------------------------------------------------------------------

# Binaries
# brew 'awscli'			-- command line interface for Amazon web services; could be useful when using Amazon braket
brew 'bash' 			# Latest Bash version
brew 'coreutils' 		# Those that come with macOS are outdated
brew 'cmake'			# Cross platform compiler; mainly used for C/C++
brew 'direnv'			# Per-directory env loading; auto-enters Nix dev shells via .envrc
# brew 'gh'			# GitHub CLI
brew 'git'
brew 'git-filter-repo'		# Quickly rewrite git repository history
brew 'git-lfs'			# Git extension for versioning large binary files
brew 'gnupg'			# GNU Privacy Guard to encrypt data (used in tlmgr)
brew 'jq'			# JSON processor (used to merge the Claude Desktop MCP config)
brew 'libomp'			# LLVM's OpenMP runtime library
brew 'llvm'       # LLVM's clangd compiler for LSP integration to neovim and claude code
brew 'dockutil'			# Manage macOS Dock items from the command line
brew 'mas' 			# Mac App Store CLI
brew 'nano'			# Minimal terminal editor for quick edits
brew 'node'			# Node.js runtime; required by several neovim LSP servers
brew 'openconnect'		# Open client for Cisco AnyConnect VPN
brew 'parallel'			# Shell command parallelization utility
brew 'pkg-config'		# Helper tool to compile applications and libraries
brew 'pipx'			# Install Python CLI apps in isolated venvs (used for paperbase)
brew 'pyenv'
brew 'neovim'			# Modern vim for terminal editing
brew 'tmux'			# Terminal multiplexer
brew 'tree'			# Recursive directory listing
# brew 'svn' 			# Needed to install fonts

# Document / LaTeX toolchain (global: the LaTeX setup itself is machine-wide)
brew 'ghostscript'		# PostScript/PDF interpreter; ImageMagick needs it for PDF input
brew 'imagemagick'		# Image format conversion on the CLI (magick)
brew 'latexdiff'		# Marked-up diff of two LaTeX documents (not shipped via Texfile)
brew 'poppler'			# PDF utilities: pdftotext, pdfimages, pdfinfo

# Apps
cask 'adobe-acrobat-reader'	
cask 'basictex'
# cask 'caffeine'
cask 'claude'
# cask 'clion'
cask 'discord'
cask 'obsidian'
# cask 'docker'			-- Software for isolating applications in containers
# cask 'flutter'
# cask 'github'
cask 'google-chrome'
cask 'inkscape'
# cask 'insomnia'		-- Design, debug, and test APIs locally or in the cloud
# cask 'intellij-idea'
cask 'microsoft-excel'
cask 'microsoft-powerpoint'
cask 'microsoft-word'
cask 'miniconda'
cask 'onedrive'
# cask 'pycharm'
# cask 'raspberry-pi-imager'	-- Imaging utility to install operating systems to a microSD card
# cask 'slack'			-- Team communication and collaboration software
cask 'spotify'
cask 'skim'			# PDF viewer with SyncTeX support for neovim
cask 'texshop'
# cask 'tuple'			-- Remote pair programming app
cask 'zoom'

# Mac App Store
mas 'AusweisApp', id: 948660805	# German eID (Personalausweis) reader
mas 'Keynote', id: 409183694
