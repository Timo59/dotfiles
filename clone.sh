#!/opt/homebrew/bin/bash

# Add timestamp to all output
exec > >(while IFS= read -r line; do echo "$(date '+%Y-%m-%d %H:%M:%S'): $line"; done) 2>&1

CODE_DIR="$HOME/Code"

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


# Loop over the associative array and clone/update each repository
for REPO_URL in "${!REPOS[@]}"; do
  TARGET_DIR="${REPOS[$REPO_URL]}"

  if [ ! -d $TARGET_DIR ]; then
    echo "Cloning $REPO_URL..."
    # Clone the main repository Qonvex Optimization with its submodules
    /opt/homebrew/bin/git clone --recurse-submodules $REPO_URL $TARGET_DIR

  else
    echo "Updating $TARGET_DIR..."
    cd "$TARGET_DIR" || continue
    /opt/homebrew/bin/git pull origin "$(/opt/homebrew/bin/git rev-parse --abbrev-ref HEAD)"

  fi
done
