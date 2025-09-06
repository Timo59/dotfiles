#!/bin/zsh

# Check if script is run from the .dotfiles directory
if [[ ! "$(basename "$PWD")" == ".dotfiles" ]]; then
  echo "[ERROR] This script must be run from inside the .dotfiles directory"
  exit 1
fi

echo "Setting up your Mac..."

# Check whether .oh-my-zsh file is in home directory and install otherwise.
# Do not run zsh when installation has finished
if ! [ -e $HOME/.oh-my-zsh ]; then
  echo 'Installing Oh-my-zsh...'
  /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)" bash --unattended
fi
echo "[DONE] Oh-my-zsh installed."
 
# Check for Homebrew and install if it is not installed yet
if test ! $(command -v brew); then
  echo 'Installing Homebrew...'
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
echo "[DONE] Homebrew installed."

# Removes .zshrc from $HOME (if it exists) and symlinks the .zshrc file from the .dotfiles
if [ -f ".zshrc" ]; then
  rm -rf $HOME/.zshrc
  ln -s "$PWD/.zshrc" "$HOME/.zshrc"
  echo "[DONE] Linked .zshrc"
else
  echo "[WARNING] .zshrc not found in $(pwd)"
fi

# Update Homebrew recipes
brew update

# Install all dependencies with homebrew/bundle (See Brewfile)
echo "Install Homebrew dependencies..."
if [ -f "./Brewfile" ]; then
  brew bundle --file ./Brewfile
  echo "[DONE] Installed Homebrew dependencies"
else
  echo "[WARNING] Brewfile not found at $(pwd), skipping Homebrew dependency installation."
fi

# Add MacTex CLI to the path and manpath
eval "$(/usr/libexec/path_helper)"

# Install LaTex dependencies and link texmf
if [ -f "./tex.sh" ]; then
  chmod +x "./tex.sh"
  "./tex.sh"
else
  echo "[WARNING] tex.sh not found in $(pwd), skipping LaTeX initialization"
fi

# Reload shell config
source $HOME/.zshrc

# Create directories
if [ -f "./dirs.sh" ]; then
  chmod +x "./dirs.sh"
  ./dirs.sh
else
  echo "[WARNING] dirs.sh not found in $(pwd), skipping directory setup"
fi 

# Clone Github repositories
if [ -f "./clone.sh" ]; then
  chmod +x "./clone.sh"
  ./clone.sh
else
  echo "[WARNING] clone.sh not found in $(pwd), skipping git initialization"
fi

# Add gitupdate, which calls clone.sh to LaunchAgents and load it
if [ -f ./com.user.gitupdate.plist ]; then
  echo "Symlinking gitupdate.plist to LaunchAgents"
  
  if [ ! -L $HOME/Library/LaunchAgents/com.user.gitupdate.plist ]; then
    # Create directory for launch agents if if not present
    if [ ! -d $HOME/Library/LaunchAgents ]; then
      mkdir $HOME/Library/LaunchAgents
    fi

    ln -s $PWD/com.user.gitupdate.plist ~/Library/LaunchAgents/com.user.gitupdate.plist
    echo "[DONE] Symlinked gitupdate.plist to LaunchAgents"
  else
    echo "[EXISTS] Symlink gitupdate.plist to LaunchAgents"
  fi

  launchctl load ~/Library/LaunchAgents/com.user.gitupdate.plist

else
  echo "[WARNING] com.user.gitupdate.plist not found in $(pwd), skipping gitupdate"
fi

# Symlink vpn scripts to usr/local/bin
if [ -f "./vpn-LUH.sh" ]; then
  echo "Symlinking vpn scripts to /usr/local/bin..."
  chmod +x ./vpn-LUH.sh
  
  if [ ! -L /usr/local/bin/vpn-LUH.sh ]; then
    # Create directory if not present
    if [ ! -d /usr/local/bin ]; then
      sudo mkdir -p /usr/local/bin
    fi

    sudo ln -s ./vpn-LUH.sh /usr/local/bin/vpn-LUH.sh
    echo "[DONE] Symlinked vpn-LUH to /usr/local/bin"
  else
    echo "[EXISTS] Symlink vpn-LUH to /usr/local/bin"
  fi
else
  echo "[WARNING] No vpn scripts found in $(pwd), skipping vpn initialization"
fi

# Install MOSEK SDK
if [ -f ./install_mosek.sh ]; then
  echo "Installing MOSEK to $HOME/mosek..."
  chmod +x ./install_mosek.sh
  .install_mosek.sh
else
  echo "[WARNING] install_mosek.sh not found in $(pwd), skipping initialization"
fi
  

# Symlink the Mackup config file to the home directory
# ln -s ./.mackup.cfg $HOME/.mackup.cfg

# Set macOS preferences - we will run this last because this will reload the shell
# source ./.macos
