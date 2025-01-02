#!/bin/sh

echo "Cloning GitHub repositories..."

DIR=$HOME/Code

# Clone the main repository of Qonvex Optimization
git clone git@github.com:Timo59/QonvexOptimization.git $DIR/QonvexOptimization

# Initialize and update the submodules
git -C $DIR/QonvexOptimization submodule update --init --recursive
git -C $DIR/QonvexOptimization submodule sync --recursive

git clone git@github.com:Timo59/VQAPySim.git $DIR/VQAPySim
