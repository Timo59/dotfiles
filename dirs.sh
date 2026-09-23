#!/bin/zsh
# =============================================================================
# dirs.sh - Directory structure creation script
# =============================================================================
# Creates the local directory structure that clone.sh writes into.
#
# Created directories:
#   ~/Code     — source repositories (orkan, optlib, TensorNetworks, ...)
#   ~/Projects — writing and project repositories (thesis, paperbase, ...)
#
# Deliberately NOT created here: ~/Documents/{Conferences:Seminars,LUH,PhD,
# Projects}. Those are symlinks into ~/Library/CloudStorage/OneDrive-Personal
# and are placed by OneDrive itself. Creating them as real directories first
# blocks OneDrive from putting its link there, which is what earlier versions
# of this script did.
#
# Note that ~/Projects and ~/Documents/Projects are different things: the
# former is local git checkouts, the latter is OneDrive-synced material.
# =============================================================================

# Associative array of directories to create (path: description)
declare -A directories
directories=(
    ["$HOME/Code"]="Code"
    ["$HOME/Projects"]="Projects"
)

echo "Setting up directory structure..."

# Function to create directory
create_directory() {
    local full_path="$1"
    local dir_name="$2"
    
    if [ ! -d "$full_path" ]; then
        # Try multiple approaches to mkdir
        if command -v mkdir >/dev/null 2>&1; then
            mkdir -p "$full_path" && echo "[DONE] Created $dir_name"
        elif [ -x "/bin/mkdir" ]; then
            /bin/mkdir -p "$full_path" && echo "[DONE] Created $dir_name"
        else
            echo "[ERROR] Could not find mkdir anywhere, $dir_name was not created"
        fi
    else
        echo "[EXISTS] $dir_name"
    fi
}

# Create all directories
for path in "${(@k)directories}"; do
    create_directory "$path" "${directories[$path]}"
done

echo "[DONE] Set up directory structure."
