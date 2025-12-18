#!/bin/zsh

# Add timestamp to all output
# exec > >(while IFS= read -r line; do echo "$(date '+%Y-%m-%d %H:%M:%S'): $line"; done) 2>&1

timestamp() {
  while IFS= read -r line; do
    printf "%s: %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$line"
  done
}
{
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


# Loop over the associative array and clone/update each repository
for repo_url in "${(@k)REPOS}"; do
    target_dir="${REPOS[$repo_url]}"
    
    if [ ! -d "$target_dir" ]; then
        clone_repo "$repo_url" "$target_dir"
    else
        update_repo "$target_dir"
    fi
done
} | timestamp
