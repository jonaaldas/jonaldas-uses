#!/bin/bash

# Configuration
REPO_DIR="$HOME/Documents/CODE/sync-script"  # Your GitHub repo path
BRANCH="main"

# Files to monitor and their destinations in the repo
declare -a CONFIG_FILES=(
    "$HOME/.zshrc:.zshrc"
    "$HOME/app.txt:app.txt"
    "$HOME/Library/Application Support/Cursor/User/settings.json:cursor-settings.json"
    # Add more files as needed: "source_path:destination_name"
)

# Extract source paths for fswatch
SOURCE_PATHS=()
for config in "${CONFIG_FILES[@]}"; do
    IFS=':' read -r source dest <<< "$config"
    if [[ -f "$source" ]]; then
        SOURCE_PATHS+=("$source")
    fi
done

# Function to copy files to repo and push changes
sync_and_push() {
    cd "$REPO_DIR" || exit 1
    
    echo "$(date): Changes detected, syncing files..."
    
    # Copy all monitored files to repo
    for config in "${CONFIG_FILES[@]}"; do
        IFS=':' read -r source dest <<< "$config"
        if [[ -f "$source" ]]; then
            cp "$source" "$REPO_DIR/$dest"
            echo "📋 Copied: $source → $dest"
        fi
    done
    
    # Check if there are changes to commit
    if [[ -n $(git status --porcelain) ]]; then
        echo "📝 Committing and pushing changes..."
        git add .
        git commit -m "Auto-update configs - $(date '+%Y-%m-%d %H:%M:%S')"
        git push origin "$BRANCH"
        echo "✅ Changes pushed successfully!"
    else
        echo "ℹ️ No changes to commit"
    fi
}

# Initial sync
echo "🚀 Starting config file monitor..."
echo "📁 Repository: $REPO_DIR"
echo "👀 Monitoring files:"
for config in "${CONFIG_FILES[@]}"; do
    IFS=':' read -r source dest <<< "$config"
    echo "  • $source → $dest"
done
echo "---"

# Do initial sync
sync_and_push
echo "---"

# Monitor files and sync when they change
if [[ ${#SOURCE_PATHS[@]} -eq 0 ]]; then
    echo "❌ No valid files found to monitor"
    exit 1
fi

fswatch -o "${SOURCE_PATHS[@]}" | while read -r num; do
    sync_and_push
done