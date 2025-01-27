#!/bin/zsh

echo "Setting up your Mac..."

# Check whether .oh-my-zsh file is in home directory and install otherwise.
# Do not run zsh when installation has finished
if ! [ -e $HOME/.oh-my-zsh ]; then
  echo 'Installing Oh-my-zsh...'
  /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)" bash --unattended
else
  echo 'Oh-my-zsh already installed'
fi
 
# Check for Homebrew and install if we don't have it
if test ! $(command -v brew); then
  echo 'Installing Homebrew...'
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo 'Homebrew already installed'
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
sudo tlmgr install $(grep -v '^\s*#' Texfile | sed 's/#.*//' | tr -s '' | tr "\n" " ")

# Copy and activate local texmf
./tex.sh

source $HOME/.zshrc

# Install the relevant python versions and set the global
if ! [ -e $PYENV_ROOT/versions/3.9* ]; then
  pyenv install 3.9
fi
if ! [ -e $PYENV_ROOT/versions/3.12* ]; then
  pyenv install 3.12
fi
pyenv global 3.12
pip install --upgrade pip 

# Install all requirements from a pip requirement.txt file - https://pip.pypa.io/en/stable/reference/requirements-file-format/
pip install --requirement Pyfile

# Create a projects directories
if ! [ -e $HOME/Code ]; then
  mkdir $HOME/Code
fi

# Clone Github repositories
./clone.sh

if ! [ -e $HOME/Private ]; then
  mkdir $HOME/Private
fi

# Copy vpn scripts to usr/local/bin
echo 'Copying vpn scripts...'
sudo cp vpn-LUH.sh usr/local/bin

# Symlink the Mackup config file to the home directory
# ln -s ./.mackup.cfg $HOME/.mackup.cfg

# Set macOS preferences - we will run this last because this will reload the shell
# source ./.macos
