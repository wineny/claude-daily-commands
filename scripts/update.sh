#!/bin/bash
# update.sh - Update claude-daily-commands to the latest version

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Determine repository directory
# Option 1: Run from repo directory
if git rev-parse --is-inside-work-tree &>/dev/null; then
  REPO_DIR=$(git rev-parse --show-toplevel)
# Option 2: Default location
elif [ -d "$HOME/claude-daily-commands" ]; then
  REPO_DIR="$HOME/claude-daily-commands"
# Option 3: Development location
elif [ -d "$HOME/development/claude-daily-commands" ]; then
  REPO_DIR="$HOME/development/claude-daily-commands"
else
  echo -e "${RED}❌ Error: claude-daily-commands not found${NC}"
  echo "💡 Please install first: curl -fsSL https://raw.githubusercontent.com/wineny/claude-daily-commands/main/install.sh | bash"
  exit 1
fi

cd "$REPO_DIR"

# Check if it's a git repository
if [ ! -d ".git" ]; then
  echo -e "${RED}❌ Error: Not a git repository${NC}"
  echo "💡 Please reinstall: curl -fsSL https://raw.githubusercontent.com/wineny/claude-daily-commands/main/install.sh | bash"
  exit 1
fi

echo "🔍 Checking for updates..."
echo ""

# Fetch latest from remote
git fetch origin -q 2>/dev/null || {
  echo -e "${RED}❌ Failed to fetch updates${NC}"
  echo "💡 Check your internet connection"
  exit 1
}

# Get current and remote versions
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" = "$REMOTE" ]; then
  echo -e "${GREEN}✅ Already up to date!${NC}"
  echo "📦 Current version: $(git log -1 --pretty=format:'%h - %s')"
  exit 0
fi

# Show available updates
echo -e "${BLUE}📦 New updates available:${NC}"
echo ""
git log --pretty=format:"  ${GREEN}✓${NC} %s" HEAD..origin/main
echo ""
echo ""

# Check-only mode
if [ "$1" = "--check-only" ]; then
  echo -e "${YELLOW}💡 Run './scripts/update.sh' to update${NC}"
  exit 0
fi

# Prompt user
read -p "$(echo -e "${BLUE}Update now? (y/n)${NC} ")" -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}❌ Update cancelled${NC}"
  exit 0
fi

echo ""
echo "🔄 Updating..."

# Pull latest changes
git pull origin main

# Reinstall commands
echo "📝 Reinstalling commands..."
cp -f .claude/commands/* ~/.claude/commands/

echo ""
echo -e "${GREEN}✅ Update complete!${NC}"
echo ""
echo "📌 Changes:"
git log --pretty=format:"  ${GREEN}✓${NC} %s" $LOCAL..HEAD
echo ""
echo ""
echo -e "${YELLOW}🔄 Please restart Claude Code to apply changes${NC}"
