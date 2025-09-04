#!/bin/bash

# Configuration
REPO_DIR="$HOME/Documents/CODE/sync-script"  # Your GitHub repo path
BRANCH="main"

# Files to monitor in their original locations
declare -a FILES_TO_WATCH=(
    "$HOME/.zshrc"
    "$HOME/app.txt"
    "$HOME/Library/Application Support/Cursor/User/settings.json"
    # Add any other files you want to monitor
)

# Function to commit and push changes
push_changes() {
    cd "$REPO_DIR" || exit 1
    
    if [[ -n $(git status --porcelain) ]]; then
        echo "$(date): Changes detected, pushing to GitHub..."
        git add .
        git commit -m "Auto-update configs - $(date '+%Y-%m-%d %H:%M:%S')"
        git push origin "$BRANCH"
        echo "✅ Changes pushed successfully!"
    fi
}

echo "Monitoring config files in their original locations..."
echo "Files being watched:"
for file in "${FILES_TO_WATCH[@]}"; do
    echo "  • $file"
done

# Monitor all files and push when any change
fswatch -o "${FILES_TO_WATCH[@]}" | while read -r num; do
    push_changes
done