#!/bin/zsh

# SSH Key Generation Script for GitHub
# Usage: ./ssh-setup.sh

SSH_KEY_PATH="$HOME/.ssh/id_github"

echo "Setting up SSH key for GitHub with email: $EMAIL"

# Check if SSH key already exists
if [ -f "$SSH_KEY_PATH" ]; then
    echo "SSH key already exists at $SSH_KEY_PATH"
    read -q "[REPLY] Do you want to overwrite it? (y/N): "
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping SSH key generation"
        exit 0
    fi
fi

# Create .ssh directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

echo "Generating a new SSH key for GitHub..."

# Generate SSH key with passphrase
echo "You will be prompted to enter a passphrase for your SSH key."
echo "This adds an extra layer of security to your private key."
ssh-keygen -t ed25519 -C "MacBook Pro" -f "$SSH_KEY_PATH"

# Check if ssh-keygen was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to generate SSH key"
    exit 1
fi

echo "SSH key generated successfully!"

# Start ssh-agent if not running
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    eval "$(ssh-agent -s)"
fi

# Create or update SSH config
SSH_CONFIG="$HOME/.ssh/config"
echo "Setting up SSH configuration..."

# Create config file if it doesn't exist
if [ ! -f "$SSH_CONFIG" ]; then
    touch "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
fi

# Check if GitHub config already exists
if ! grep -q "Host github.com" "$SSH_CONFIG"; then
    echo "Adding GitHub configuration to SSH config..."
    cat >> "$SSH_CONFIG" << EOF

# GitHub configuration
Host github.com
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_github
    HostName github.com
    User git

EOF
else
    echo "GitHub SSH configuration already exists in $SSH_CONFIG"
fi

# Add key to ssh-agent and keychain (macOS)
echo "Adding SSH key to ssh-agent..."
echo "You'll need to enter your passphrase to add the key to the keychain."

if ssh-add --apple-use-keychain "$SSH_KEY_PATH" 2>/dev/null; then
    echo "SSH key added to ssh-agent and keychain successfully"
    echo "Your passphrase has been saved to the macOS keychain"
else
    # Fallback for older macOS versions or if --apple-use-keychain doesn't work
    if ssh-add -K "$SSH_KEY_PATH" 2>/dev/null; then
        echo "SSH key added to ssh-agent and keychain successfully"
        echo "Your passphrase has been saved to the macOS keychain"
    else
        # Final fallback
        ssh-add "$SSH_KEY_PATH"
        echo "SSH key added to ssh-agent (passphrase not saved to keychain)"
    fi
fi

# Copy public key to clipboard
if command -v pbcopy >/dev/null 2>&1; then
    pbcopy < "${SSH_KEY_PATH}.pub"
    echo "SSH public key copied to clipboard!"
    echo ""
    echo "Next steps:"
    echo "1. Go to GitHub.com → Settings → SSH and GPG keys"
    echo "2. Click 'New SSH key'"
    echo "3. Paste the key (already in your clipboard) and give it a title"
    echo "4. Click 'Add SSH key'"
    echo ""
    echo "Your public key is:"
    cat "${SSH_KEY_PATH}.pub"
else
    echo "To add this key to GitHub:"
    echo "1. Copy the following public key:"
    echo ""
    cat "${SSH_KEY_PATH}.pub"
    echo ""
    echo "2. Go to GitHub.com → Settings → SSH and GPG keys"
    echo "3. Click 'New SSH key' and paste the key above"
fi

echo ""
echo "[DONE] Created SSH key with passphrase for github.com"
echo ""
echo "Test your connection with: ssh -T git@github.com"
