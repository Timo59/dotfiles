# =============================================================================
# aliases.zsh - Shell command aliases
# =============================================================================
# Custom shell aliases. Loaded automatically by Oh-My-Zsh via ZSH_CUSTOM.
# =============================================================================

# Shortcuts
alias copyssh="pbcopy < $HOME/.ssh/id_ed25519.pub"
alias reloadshell="omz reload"
alias reloaddns="dscacheutil -flushcache && sudo killall -HUP mDNSResponder"

# Directories
alias dotfiles="cd $DOTFILES"

