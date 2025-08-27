#!/bin/zsh

# Array of directories to create
directories=("Conferences:Seminars" "LUH" "PhD" "Projects")

# Array of base paths
base_path="$HOME/Documents"

# Function to create directory with progress output
create_directory() {
    local full_path="$1"
    local dir_name="$2"
    
    echo "Creating $dir_name directory..."
    
    if ! [ -e "$full_path" ]; then
        mkdir -p "$full_path"
        echo -e "\033[1A\033[K[DONE] Creating $dir_name directory"
    else
        echo -e "\033[1A\033[K[EXISTS] $dir_name directory already exists"
    fi
}

echo "Setting up directories in $base_path"

for dir in "${directories[@]}"; do
    full_path="$base_path/$dir"
    create_directory "$full_path" "$dir"
done
    
echo "Creating Code directory..."

if ! [ -e "$HOME/Code" ]; then
    mkdir -p "$HOME/Code"
    echo -e "\033[1A\033[K[DONE] Creating Code directory"
else
    echo -e "\033[1A\033[K[EXISTS] Code directory already exists"
fi
