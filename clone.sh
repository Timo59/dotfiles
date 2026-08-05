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
PROJECT_DIR="$HOME/Projects"

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
  [git@github.com:Timo59/orkan.git]="$CODE_DIR/orkan"
  [git@gitlab.uni-hannover.de:timo.ziegler/optlib.git]="$CODE_DIR/optlib" 
  [git@github.com:Timo59/TensorNetworks.git]="$CODE_DIR/TensorNetworks"
  [git@gitlab.uni-hannover.de:timo.ziegler/thesis.git]="$PROJECT_DIR/thesis"
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
    
    # Pull the current branch from *its own* upstream rather than always from
    # origin. Orkan's dev branch tracks gitlab — that is where all development
    # happens; origin/GitHub only ever receives main on a release — so
    # hardcoding origin made every boot fail with "couldn't find remote ref dev".
    # Branches without a configured upstream fall back to origin/<branch>.
    #
    # --ff-only because this runs unattended at login: a boot-time pull must
    # never create a merge commit or leave a conflicted worktree behind.
    local -a pull_args
    if $GIT_CMD rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' &>/dev/null; then
        pull_args=(--ff-only)
    else
        pull_args=(--ff-only origin "$current_branch")
    fi

    if $GIT_CMD pull "${pull_args[@]}"; then
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

# Function to apply Orkan-specific git configuration (dual-remote push
# routing + project-tracked hooks). Detected by the presence of
# tools/hooks/pre-push, which only exists in the Orkan repo. Idempotent:
# safe to re-run on an already-configured clone.
configure_orkan() {
    local target_dir="$1"

    echo "Applying Orkan git configuration in $target_dir..."
    cd "$target_dir" || return 1

    # Reset existing origin push URLs so re-running doesn't duplicate them.
    # Errors are ignored — they just mean nothing matched yet.
    $GIT_CMD remote set-url --delete --push origin '.*github\.com.*' 2>/dev/null
    $GIT_CMD remote set-url --delete --push origin '.*gitlab.*'      2>/dev/null

    # Origin push URLs: GitHub primary + GitLab secondary.
    $GIT_CMD remote set-url --add --push origin git@github.com:Timo59/orkan.git \
        || echo "[WARNING] Failed to add GitHub push URL on origin"
    $GIT_CMD remote set-url --add --push origin git@gitlab.uni-hannover.de:timo.ziegler/orkan.git \
        || echo "[WARNING] Failed to add GitLab push URL on origin"

    # Separate gitlab remote for fetching dev branches that live only there.
    if $GIT_CMD remote get-url gitlab &>/dev/null; then
        $GIT_CMD remote set-url gitlab git@gitlab.uni-hannover.de:timo.ziegler/orkan.git
    else
        $GIT_CMD remote add gitlab git@gitlab.uni-hannover.de:timo.ziegler/orkan.git \
            || echo "[WARNING] Failed to add gitlab remote"
    fi

    # Fetch it so refs/remotes/gitlab/* exist. Without this a fresh clone (which
    # lands on main, the only branch GitHub has) cannot `git checkout dev` — the
    # remote-tracking ref it would branch from wouldn't be there yet. Does not
    # change the checked-out branch.
    $GIT_CMD fetch gitlab || echo "[WARNING] Failed to fetch gitlab remote"

    # Per-branch push routing: main → origin (dual URLs), everything else → gitlab.
    $GIT_CMD config remote.pushDefault gitlab
    $GIT_CMD config branch.main.pushRemote origin

    # Activate project-tracked git hooks (refuses dev branches on GitHub).
    $GIT_CMD config core.hooksPath tools/hooks

    # Ensure pre-push hook is executable.
    chmod +x tools/hooks/pre-push 2>/dev/null || true

    echo "[DONE] Orkan configuration applied"
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

    # Apply Orkan-specific configuration when the marker file is present.
    if [ -f "$target_dir/tools/hooks/pre-push" ]; then
        configure_orkan "$target_dir" || echo "[WARNING] Orkan configuration failed (continuing)"
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
