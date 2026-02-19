#!/bin/zsh
# =============================================================================
# clone.sh - Git repository management script
# =============================================================================
# Clones and updates multiple Git repositories from GitHub and GitLab.
# Called during initial setup and automatically at startup via LaunchAgent.
#
# Features:
#   - Clones repositories if they don't exist
#   - Pulls latest changes for existing repositories
#   - Handles submodules automatically
#   - Skips repositories in detached HEAD state
#   - Timestamps all output for logging
# =============================================================================

# Add timestamp to all output
# exec > >(while IFS= read -r line; do echo "$(date '+%Y-%m-%d %H:%M:%S'): $line"; done) 2>&1

timestamp() {
  while IFS= read -r line; do
    printf "%s: %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$line"
  done
}
{
# Wait for SSH connectivity to github.com before attempting any git operations.
# Times out after 60 s and exits cleanly so a machine that boots offline or on
# a network that blocks port 22 isn't left hanging.
WAIT_MAX=60
WAIT_ELAPSED=0
until nc -zw2 github.com 22 2>/dev/null; do
    if (( WAIT_ELAPSED >= WAIT_MAX )); then
        echo "[WARNING] github.com:22 unreachable after ${WAIT_MAX}s — skipping repository updates"
        exit 0
    fi
    sleep 5
    (( WAIT_ELAPSED += 5 ))
done

CODE_DIR="$HOME/Code"

# Check if Code directory exists
if [ ! -d "$CODE_DIR" ]; then
    echo "[ERROR] Code directory does not exist at $CODE_DIR."
    exit 1
fi

# Use git from homebrew since PATH is not set up during startup
GIT_CMD="/opt/homebrew/bin/git"

# Check if git is available
if ! command -v $GIT_CMD &> /dev/null; then
    echo "[ERROR] git command not found."
    exit 1
fi

# Associative array of REPO_URL to TARGET_DIR
declare -A REPOS
REPOS=(
  [git@github.com:Timo59/dotfiles.git]="$HOME/.dotfiles"
  [git@github.com:Timo59/HamSim.git]="$CODE_DIR/HamSim" 
  [git@github.com:Timo59/optlib.git]="$CODE_DIR/optlib" 
  [git@gitlab.uni-hannover.de:timo.ziegler/qsim.git]="$CODE_DIR/qlib" 
  [git@github.com:Timo59/QonvexOptimization.git]="$CODE_DIR/QonvexOptimization" 
  [git@github.com:Timo59/TensorNetworks.git]="$CODE_DIR/TensorNetworks"
  [git@gitlab.uni-hannover.de:timo.ziegler/QCP_braket.git]="$CODE_DIR/QCP_braket"
)

# Function to clone repository
clone_repo() {
    local repo_url="$1"
    local target_dir="$2"
    
    echo "Cloning $repo_url to $target_dir..."
    if $GIT_CMD clone --recurse-submodules "$repo_url" "$target_dir"; then
        echo "[DONE] Cloned $repo_url"
    else
        echo "[ERROR] Failed to clone $repo_url"
        return 1
    fi
}

# Function to update repository
update_repo() {
    local target_dir="$1"
    local repo_name=$(basename "$target_dir")
    
    echo "Updating $repo_name..."
    cd "$target_dir" || return 1
    
    # Get current branch
    local current_branch
    current_branch=$($GIT_CMD rev-parse --abbrev-ref HEAD)
    
    if [ "$current_branch" = "HEAD" ]; then
        echo "[WARNING] Repository $repo_name is in detached HEAD state, skipping update"
        return 0
    fi
    
    # Pull latest changes
    if $GIT_CMD pull origin "$current_branch"; then
        echo "[DONE] Updated $repo_name"
    else
        echo "[ERROR] Failed to update $repo_name"
        return 1
    fi
    
    # Update submodules if they exist
    if [ -f ".gitmodules" ]; then
        echo "Updating submodules for $repo_name..."
        $GIT_CMD submodule update --init --recursive
    fi
}


# Loop over the associative array and clone/update each repository.
# Track the .dotfiles commit hash before and after to detect upstream changes.
DOTFILES_BEFORE=""
DOTFILES_AFTER=""

for repo_url in "${(@k)REPOS}"; do
    target_dir="${REPOS[$repo_url]}"

    if [ "$target_dir" = "$HOME/.dotfiles" ] && [ -d "$target_dir" ]; then
        DOTFILES_BEFORE=$($GIT_CMD -C "$target_dir" rev-parse HEAD 2>/dev/null)
    fi

    if [ ! -d "$target_dir" ]; then
        clone_repo "$repo_url" "$target_dir"
    else
        update_repo "$target_dir"
    fi

    if [ "$target_dir" = "$HOME/.dotfiles" ] && [ -d "$target_dir" ]; then
        DOTFILES_AFTER=$($GIT_CMD -C "$target_dir" rev-parse HEAD 2>/dev/null)
    fi
done

# Notify if dotfiles were updated so the user knows to run setup.sh
if [ -n "$DOTFILES_BEFORE" ] && [ "$DOTFILES_BEFORE" != "$DOTFILES_AFTER" ]; then
    echo "[INFO] dotfiles updated — run: cd ~/.dotfiles && ./setup.sh"
    osascript -e 'display notification "Run cd ~/.dotfiles && ./setup.sh to apply changes." with title "dotfiles updated"'
fi
} | timestamp
