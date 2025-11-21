#!/bin/bash

# Claude Daily Commands Installer
# Supports both one-click curl install and git clone install

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# GitHub repository info
GITHUB_USER="wineny"
GITHUB_REPO="claude-daily-commands"
GITHUB_RAW="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/main"

# Banner
echo ""
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Claude Daily Commands${NC}"
echo -e "${BLUE}  Installer${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Detect installation method
if [ -d ".claude/commands" ]; then
    # Local installation (git clone method)
    INSTALL_METHOD="local"
    echo -e "${BLUE}🔍 Detected local repository${NC}"
    INTERACTIVE=true
else
    # Remote installation (curl method)
    INSTALL_METHOD="remote"
    echo -e "${BLUE}🌐 Remote installation mode${NC}"
    # For curl pipe installation, default to global + v2
    INTERACTIVE=false
fi

# Installation type selection
if [ "$INTERACTIVE" = true ]; then
    echo ""
    echo "Installation options:"
    echo "  1) Global (all projects - recommended)"
    echo "  2) Cancel"
    echo ""
    read -p "Choose installation type (1/2): " choice

    case $choice in
        1)
            INSTALL_TYPE="global"
            ;;
        2)
            echo -e "${YELLOW}Installation cancelled${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Installation cancelled${NC}"
            exit 1
            ;;
    esac

else
    # Non-interactive mode (curl pipe)
    INSTALL_TYPE="global"
    echo ""
    echo -e "${GREEN}📦 Auto-installing: Daily Review Sync Commands${NC}"
    echo ""
fi

# Install globally
echo -e "${BLUE}🌍 Installing globally...${NC}"

# Create global directory
mkdir -p ~/.claude/commands

# Download or copy files based on installation method
if [ "$INSTALL_METHOD" = "remote" ]; then
    # Remote installation - download from GitHub
    echo "Downloading command files from GitHub..."
    echo ""

    # Download dailyreview-sync command
    echo -n "  Downloading dailyreview-sync.md... "
    if curl -fsSL "${GITHUB_RAW}/.claude/commands/dailyreview-sync.md" -o ~/.claude/commands/dailyreview-sync.md 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        exit 1
    fi

    # Download scripts
    echo -n "  Downloading sync-daily-review.sh... "
    mkdir -p ~/.claude-daily-commands/scripts
    if curl -fsSL "${GITHUB_RAW}/scripts/sync-daily-review.sh" -o ~/.claude-daily-commands/scripts/sync-daily-review.sh 2>/dev/null; then
        chmod +x ~/.claude-daily-commands/scripts/sync-daily-review.sh
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        exit 1
    fi

    echo -n "  Downloading setup-ownit.sh... "
    if curl -fsSL "${GITHUB_RAW}/scripts/setup-ownit.sh" -o ~/.claude-daily-commands/scripts/setup-ownit.sh 2>/dev/null; then
        chmod +x ~/.claude-daily-commands/scripts/setup-ownit.sh
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        exit 1
    fi
else
    # Local installation - copy from local directory
    echo "Copying command files from local repository..."
    echo ""

    cp -v .claude/commands/dailyreview-sync.md ~/.claude/commands/

    # Copy scripts
    mkdir -p ~/.claude-daily-commands/scripts
    cp -v scripts/sync-daily-review.sh ~/.claude-daily-commands/scripts/
    cp -v scripts/setup-ownit.sh ~/.claude-daily-commands/scripts/
    chmod +x ~/.claude-daily-commands/scripts/sync-daily-review.sh
    chmod +x ~/.claude-daily-commands/scripts/setup-ownit.sh
fi

echo ""
echo -e "${GREEN}✅ Installation complete!${NC}"
echo ""
echo -e "📁 Commands installed to: ${BLUE}~/.claude/commands/${NC}"
echo -e "📁 Scripts installed to: ${BLUE}~/.claude-daily-commands/scripts/${NC}"
echo ""
echo "📋 Available command:"
echo ""
echo "   ${GREEN}/dailyreview-sync${NC} - Sync daily review to Own It"
echo ""
echo "📋 Available scripts:"
echo ""
echo "   ${BLUE}sync-daily-review.sh${NC} - Sync Git commits to Own It platform"
echo "   ${BLUE}setup-ownit.sh${NC} - Configure Own It API key and settings"

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}⚠️  IMPORTANT${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Restart Claude Code to see the new commands:"
echo "  • macOS: Cmd+Q, then reopen"
echo "  • Windows/Linux: Ctrl+Q, then reopen"
echo ""

# Show next steps
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Quick Start${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "1. Setup Own It integration:"
echo "   ${GREEN}~/.claude-daily-commands/scripts/setup-ownit.sh${NC}"
echo ""
echo "2. Restart Claude Code (Cmd+Q)"
echo ""
echo "3. Open any Git repository and run:"
echo "   ${GREEN}/dailyreview-sync${NC}"
echo ""

echo -e "📖 Documentation: ${BLUE}https://github.com/${GITHUB_USER}/${GITHUB_REPO}${NC}"
echo -e "🐛 Report issues: ${BLUE}https://github.com/${GITHUB_USER}/${GITHUB_REPO}/issues${NC}"
echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"
echo ""
