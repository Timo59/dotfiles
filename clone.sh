#!/bin/sh

REPO_URL=git@github.com:Timo59/QonvexOptimization.git
TARGET_DIR=$HOME/Code/QonvexOptimization

if [ ! -d $TARGET_DIR ]; then
  echo "Cloning GitHub repositories..."
  # Clone the main repository Qonvex Optimization with its submodules
  git clone --recurse-submodules $REPO_URL $TARGET_DIR

  # Copy to execute this file to .zprofile
  echo '$HOME/.dotfiles/clone.sh' >> $HOME/.zprofile
fi

# Pull all changes from the remote repository
cd $TARGET_DIR
echo "Updating main repository..."
git pull origin $(git symbolic-ref --short HEAD)
git submodule update --init --recursive

# Update each submodule
git submodule foreach '
  echo "Updating $name..."
  BRANCH=$(git rev-parse --abbrev-ref HEAD)

   if [ -z "$BRANCH" ] || [ "$BRANCH" == "HEAD" ]; then
     # Resolve to default branch if in a detached state or HEAD is not a symbolic ref
     BRANCH=$(git config -f $toplevel/.gitmodules submodule.$name.branch || echo "main")
  fi
  git fetch --all
  git checkout $BRANCH
  git pull origin $BRANCH
'
