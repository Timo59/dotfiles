# =============================================================================
# aliases.zsh - Shell command aliases
# =============================================================================
# Custom shell aliases. Loaded automatically by Oh-My-Zsh via ZSH_CUSTOM.
# =============================================================================

# Shortcuts
alias copyssh="pbcopy < $HOME/.ssh/id_github.pub"
alias reloadshell="omz reload"
alias reloaddns="dscacheutil -flushcache && sudo killall -HUP mDNSResponder"

# Directories
alias dotfiles="cd $DOTFILES"

