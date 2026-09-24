#!/bin/zsh
# =============================================================================
# ssh-setup.sh - SSH key generation for GitHub and GitLab
# =============================================================================
# Generates one ed25519 key per forge, writes the matching ~/.ssh/config
# blocks, and loads the keys into ssh-agent + the macOS Keychain.
#
# Two keys, not one: GitHub and gitlab.uni-hannover.de are separate accounts
# with separate key lists, and a single key shared between a personal and a
# university identity is the kind of thing that becomes awkward to revoke.
# A per-host IdentityFile also stops ssh from offering the wrong key first
# and tripping GitLab's auth attempt limit.
#
# Run this BEFORE setup.sh: clone.sh needs GitHub for dotfiles/orkan/
# TensorNetworks, GitLab for optlib/thesis, and paperbase.sh pip-installs
# straight from the GitLab repo. Without both keys those steps fail.
#
# Usage: ./ssh-setup.sh
# =============================================================================

EMAIL="${EMAIL:-ziegler-timo@web.de}"
KEY_COMMENT="$EMAIL ($(hostname -s))"

SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [ ! -f "$SSH_CONFIG" ]; then
    touch "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
fi

# Start ssh-agent if it is not already running
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    eval "$(ssh-agent -s)" > /dev/null
fi

# -----------------------------------------------------------------------------
# Per-forge setup
# -----------------------------------------------------------------------------
# setup_forge <host> <key path> <label> <where to paste the key>
setup_forge() {
    local host="$1"
    local key_path="$2"
    local label="$3"
    local key_page="$4"

    echo ""
    echo "=== $label ($host) ==="

    # 1. Key
    if [ -f "$key_path" ]; then
        echo "[EXISTS] SSH key at $key_path"
        local REPLY
        read -q "REPLY?Regenerate it? This invalidates the key on $label. (y/N): "
        echo
        if [[ "$REPLY" != [Yy] ]]; then
            echo "[INFO] Keeping existing $label key"
        else
            rm -f "$key_path" "${key_path}.pub"
        fi
    fi

    if [ ! -f "$key_path" ]; then
        echo "Generating an ed25519 key for $label..."
        echo "You will be prompted for a passphrase (stored in the Keychain below)."
        if ! ssh-keygen -t ed25519 -C "$KEY_COMMENT" -f "$key_path"; then
            echo "[ERROR] Failed to generate the $label key"
            return 1
        fi
        echo "[DONE] Generated $key_path"
    fi

    # 2. ~/.ssh/config block
    if grep -q "^Host $host\$" "$SSH_CONFIG"; then
        echo "[EXISTS] $host block in $SSH_CONFIG"
    else
        cat >> "$SSH_CONFIG" << EOF

# $label
Host $host
    HostName $host
    User git
    IdentityFile $key_path
    IdentitiesOnly yes
    AddKeysToAgent yes
    UseKeychain yes
EOF
        echo "[DONE] Added $host block to $SSH_CONFIG"
    fi

    # 3. ssh-agent + Keychain. --apple-use-keychain is the current flag; -K is
    # the pre-Monterey spelling, kept as a fallback.
    if ssh-add --apple-use-keychain "$key_path" 2>/dev/null \
        || ssh-add -K "$key_path" 2>/dev/null; then
        echo "[DONE] Added $label key to ssh-agent and Keychain"
    elif ssh-add "$key_path" 2>/dev/null; then
        echo "[WARNING] Added $label key to ssh-agent only (passphrase not saved)"
    else
        echo "[WARNING] Could not add the $label key to ssh-agent"
    fi

    # 4. Hand the public key to the human
    echo ""
    echo "Add this key to $label:"
    echo "  $key_page"
    echo ""
    cat "${key_path}.pub"
    echo ""
    if command -v pbcopy >/dev/null 2>&1; then
        pbcopy < "${key_path}.pub"
        echo "[DONE] Public key copied to clipboard"
    fi
    read -q "REPLY?Press y once the key is added (any other key to skip the test): "
    echo

    # 5. Verify. Both forges answer an auth probe with exit code 1 and a
    # greeting on success, so match the greeting rather than the status.
    if [[ "$REPLY" == [Yy] ]]; then
        if ssh -o StrictHostKeyChecking=accept-new -T "git@$host" 2>&1 \
            | grep -qiE "successfully authenticated|Welcome to GitLab|logged in as"; then
            echo "[DONE] Authenticated to $label"
        else
            echo "[WARNING] Could not authenticate to $label — check the key was added"
        fi
    fi
}

echo "Setting up SSH keys for $EMAIL on $(hostname -s)..."

setup_forge "github.com" "$SSH_DIR/id_github" \
    "GitHub" "https://github.com/settings/ssh/new"

setup_forge "gitlab.uni-hannover.de" "$SSH_DIR/id_gitlab_luh" \
    "GitLab LUH" "https://gitlab.uni-hannover.de/-/user_settings/ssh_keys"

echo ""
echo "[DONE] SSH setup complete. Next: cd ~/.dotfiles && ./setup.sh"
