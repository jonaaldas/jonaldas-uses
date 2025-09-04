# Config File Monitor Setup for macOS

This guide will help you set up an automatic GitHub push system that monitors your config files (like `settings.json` and `app.txt`) for changes and pushes them to GitHub automatically.

## Prerequisites

- macOS with Homebrew installed
- Git repository already set up
- GitHub account with repository access

## Step 1: Install fswatch

Open Terminal and install fswatch using Homebrew:

```bash
brew install fswatch
```

If you don't have Homebrew installed, install it first:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## Step 2: Create the monitoring script

Navigate to your repository directory and create the script:

```bash
cd /path/to/your/repo
nano config-monitor.sh
```

Copy and paste this script (update the configuration section):

```bash
#!/bin/bash

# Configuration
REPO_DIR="repo dir"  # Your GitHub repo path
BRANCH="main"

# Files to monitor and their destinations in the repo
declare -a CONFIG_FILES=(
    "$HOME/../"
    "../"
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
```

## Step 3: Make the script executable

```bash
chmod +x config-monitor.sh
```

## Step 4: Configure Git authentication

### Option A: SSH Key (Recommended)

1. **Generate SSH key:**

   ```bash
   ssh-keygen -t ed25519 -C "your.email@example.com"
   ```

2. **Add SSH key to ssh-agent:**

   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519
   ```

3. **Copy public key to clipboard:**

   ```bash
   pbcopy < ~/.ssh/id_ed25519.pub
   ```

4. **Add to GitHub:**

   - Go to GitHub.com → Settings → SSH and GPG keys
   - Click "New SSH key"
   - Paste the key and save

5. **Test SSH connection:**
   ```bash
   ssh -T git@github.com
   ```

## Step 6: Update script configuration

Edit the script to use your actual paths:

```bash
nano config-monitor.sh
```

Update these lines:

- `REPO_DIR="/Users/yourusername/path/to/your/repo"` - Replace with your actual repository path
- `FILES_TO_WATCH=("settings.json" "app.txt")` - Add/remove files you want to monitor
- `BRANCH="main"` - Change if you use a different default branch

## Step 7: Test the script

1. **Run the script:**

   ```bash
   ./config-monitor.sh
   ```

2. **Test monitoring:** In another Terminal window, make a change to one of your config files:

   ```bash
   echo "# Test change" >> settings.json
   ```

3. **Verify output:** You should see something like:
   ```
   2025-09-04 17:00:15: 🔍 Changes detected in config files
   📝 Staging and committing changes...
   ✅ Changes pushed to GitHub successfully!
   ```

## Step 8: Run as background service

### Option A: Simple background process

```bash
# Run in background
nohup ./config-monitor.sh > config-monitor.log 2>&1 &

# Check if running
ps aux | grep fswatch

# Stop the process (replace XXXX with actual PID)
kill XXXX
```

3. **Load and start the service:**

   ```bash
   launchctl load ~/Library/LaunchAgents/com.user.config-monitor.plist
   launchctl start com.user.config-monitor
   ```

4. **Check service status:**

   ```bash
   launchctl list | grep config-monitor
   ```

5. **Stop and unload service:**
   ```bash
   launchctl stop com.user.config-monitor
   launchctl unload ~/Library/LaunchAgents/com.user.config-monitor.plist
   ```

## Troubleshooting

### Common Issues

**fswatch command not found:**

```bash
# Check if fswatch is installed
which fswatch
# If not found, reinstall
brew reinstall fswatch
```

**Permission denied:**

```bash
# Make sure script is executable
chmod +x config-monitor.sh
```

**Git push authentication fails:**

```bash
# Test manual push
git push origin main
# If fails, reconfigure authentication (see Step 4)
```

**Files not being detected:**

- Verify file paths are correct and files exist
- Check if files are in the repository
- Ensure you're in the correct directory

### Checking logs

**For background process:**

```bash
tail -f config-monitor.log
```

**For launchd service:**

```bash
tail -f ~/config-monitor.log
tail -f ~/config-monitor-error.log
```

## Usage Tips

- The script will automatically commit and push changes whenever you save your config files
- Each commit includes a timestamp for easy tracking
- You can add more files to monitor by updating the `FILES_TO_WATCH` array
- The script only commits the specified files, not all changes in the repository

## Security Notes

- Keep your SSH keys and access tokens secure
- Consider using a dedicated repository for config files
- Review commits periodically to ensure no sensitive data is being pushed

Your config file monitor is now set up and ready to automatically sync your configuration changes to GitHub! 🎉
