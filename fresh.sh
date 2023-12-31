#!/bin/bash

echo "Setting up your Mac..."

# Check whether .oh-my-zsh file is in home directory and install otherwise.
# Do not run zsh when installation has finished - https://github.com/ohmyzsh/ohmyzsh#unattended-install
if ! [ -e $HOME/.oh-my-zsh ]; then
  /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)" bash --unattended
fi

echo "Oh My Zsh installed"
 
# Check for Homebrew and install if we don't have it
if test ! $(command -v brew); then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Removes .zshrc from $HOME (if it exists) and symlinks the .zshrc file from the .dotfiles
rm -rf $HOME/.zshrc
ln -s .dotfiles/.zshrc $HOME/.zshrc

# Update Homebrew recipes
brew update

# Install all dependencies with homebrew/bundle (See Brewfile)
brew tap homebrew/bundle
brew bundle --file ./Brewfile

# Add MacTex CLI to the path and manpath
eval "$(/usr/libexec/path_helper)"

# Install all LaTex dependencies using tlmgr from newline delimited list Texfile
sudo tlmgr update --self
sudo tlmgr install $(tail -n +2 Texfile | tr "\n" " ")

# Create a projects directories
# mkdir $HOME/Code
# mkdir $HOME/Herd

# Create Code subdirectories
# mkdir $HOME/Code/blade-ui-kit
# mkdir $HOME/Code/laravel

# Clone Github repositories
# ./clone.sh

# Symlink the Mackup config file to the home directory
# ln -s ./.mackup.cfg $HOME/.mackup.cfg

# Set macOS preferences - we will run this last because this will reload the shell
# source ./.macos