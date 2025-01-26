#!/bin/sh

REPO_URL=git@github.com:Timo59/QonvexOptimization.git
TARGET_DIR=$HOME/Code/QonvexOptimization

if [ ! -d $TARGET_DIR ]; then
  echo "Cloning GitHub repositories..."
  # Clone the main repository Qonvex Optimization with its submodules
  git clone --recurse-submodules $REPO_URL $TARGET_DIR
fi

# Pull all changes from the remote repository
cd $TARGET_DIR
echo "Updating main repository..."
git submodule update --init --recursive

# Update each submodule
git submodule foreach '
  echo "Updating $name..."
  BRANCH=$(git symbolic-ref --short HEAD)
  git fetch --all
  git pull origin $BRANCH
'
