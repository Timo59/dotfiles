#!/bin/zsh

# Associative array of directories to create (path: description)
declare -A directories
directories=(
    ["$HOME/Documents/Conferences:Seminars"]="Conferences:Seminars"
    ["$HOME/Documents/LUH"]="LUH"
    ["$HOME/Documents/PhD"]="PhD"
    ["$HOME/Documents/Projects"]="Projects"
    ["$HOME/Code"]="Code"
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
