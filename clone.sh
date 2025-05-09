#!/bin/bash

CODE_DIR="$HOME/Code"

# Associative array of REPO_URL to TARGET_DIR
declare -A REPOS
REPOS=(
  [git@github.com:Timo59/HamSim.git]="$CODE_DIR/HamSim" 
  [git@github.com:Timo59/optlib.git]="$CODE_DIR/optlib" 
  [git@github.com:Timo59/qlib.git]="$CODE_DIR/qlib" 
  [git@github.com:Timo59/QonvexOptimization.git]="$CODE_DIR/QonvexOptimization" 
  [git@github.com:Timo59/TensorNetworks.git]="$CODE_DIR/TensorNetworks"
)


# Loop over the associative array and clone/update each repository
for REPO_URL in "${!REPOS[@]}"; do
  TARGET_DIR="${REPOS[$REPO_URL]}"

  if [ ! -d $TARGET_DIR ]; then
    echo "Cloning $REPO_URL..."
    # Clone the main repository Qonvex Optimization with its submodules
    git clone --recurse-submodules $REPO_URL $TARGET_DIR

  else
    echo "Updating $TARGET_DIR..."
    cd "$TARGET_DIR" || continue
    git pull origin "$(git rev-parse --abbrev-ref HEAD)"

  fi
done
