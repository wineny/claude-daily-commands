# ⚡ Claude Daily Commands

> Fast and concise Claude Code commands for daily work review and todo management

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude-Code-blue.svg)](https://claude.ai/code)
[![Version](https://img.shields.io/badge/version-0.2.0--beta-blue.svg)](https://github.com/wineny/claude-daily-commands/releases)

[English](#) | 한국어

---

## 🚀 One-Click Install

```bash
curl -fsSL https://raw.githubusercontent.com/wineny/claude-daily-commands/main/install.sh | bash
```

**Then restart Claude Code (Cmd+Q) and you're ready to go!**

---

## 📌 What is this?

**Claude Daily Commands** helps developers automate their daily work review and todo management using Claude Code's custom slash commands.

### ✨ Key Features

**v2 Optimized (Recommended)**
- **⚡ /dailyreviewv2** - 80% shorter, 85% fewer approvals, 73% faster
- **⚡ /todov2** - 70% shorter, 60% fewer approvals

**v1 (Detailed)**
- **📅 /dailyreview** - Comprehensive Git-based daily work review
- **✅ /todo** - In-depth code analysis and todo recommendations
- **💼 /portfolio** - Portfolio generation (beta)

### 📊 v1 vs v2 Comparison

| Feature | v1 | v2 (Optimized) | Improvement |
|---------|----|----|-------------|
| Output Length | ~50 lines | ~10 lines | **80% shorter** |
| Approval Requests | 8-14 times | 1-3 times | **85% fewer** |
| Execution Time | ~30 sec | ~8 sec | **73% faster** |
| Use Case | Detailed analysis | Daily quick check | Complementary |

---

## 📖 Usage Guide

### `/dailyreviewv2` - Fast Daily Review

```bash
# Quick summary (default - 10 lines)
/dailyreviewv2

# Ultra-compact (3 lines)
/dailyreviewv2 --brief

# Detailed (v1 level)
/dailyreviewv2 --full

# Yesterday or weekly
/dailyreviewv2 yesterday
/dailyreviewv2 week
```

**Example Output (default):**
```markdown
# 📅 Daily Review - 2025.11.09

**2 commits | 7 files | +755 lines**

18:07 feat: Add basic authentication module (src/auth)
18:07 feat: Add custom Claude Code commands (.claude/commands)

💡 Main work: Authentication module, custom commands
```

📄 [More examples](./examples/dailyreview-v2-example.md)

---

### `/todov2` - Quick Todo List

```bash
# Concise list (default - 15 lines)
/todov2

# Ultra-brief stats (2 lines)
/todov2 --brief

# Priority items only
/todov2 --priority-only

# Detailed (v1 level)
/todov2 --full

# Specific directory
/todov2 @src/
```

**Example Output (default):**
```markdown
# ✅ Todo (6 found)

## 🔴 Urgent (2)
1. src/auth/login.ts:3 - FIXME: Implement auth logic
2. src/payment/stripe.ts:12 - BUG: Rollback missing

## 🟡 Normal (2)
3. src/auth/login.ts:4 - Remove console.log
4. tests/auth.test.ts:4 - Add test cases

## 🔵 Improvements (2)
5. tests/auth.test.ts:10 - Test failure cases
6. src/auth/login.ts:14 - Improve temp implementation
```

📄 [More examples](./examples/todo-v2-example.md)

---

## 🛠️ Advanced Options

### v1 Commands (Detailed Analysis)

If you need comprehensive analysis, use v1:

```bash
/dailyreview           # Detailed daily review
/dailyreview --detailed # With code diffs
/todo                  # Comprehensive todo analysis
/todo @src/            # Specific directory
```

**When to use v1:**
- Weekly reports
- Code reviews
- Onboarding documentation
- Blog post drafts

**When to use v2:**
- Daily routine
- Quick status checks
- Team standup prep
- Slack/Discord sharing

---

## 🎯 Use Cases

### Morning Routine (5 seconds)
```bash
/dailyreviewv2 yesterday --brief   # What did I do?
/todov2 --priority-only            # What's urgent today?
```

### Evening Wrap-up (10 seconds)
```bash
/dailyreviewv2                     # Today's summary
/todov2                            # Tomorrow's plan
```

### Weekly Review (Detailed)
```bash
/dailyreviewv2 week --full         # Full weekly report
/todov2 --full                     # Comprehensive todo analysis
```

---

## 📦 Installation Methods

### Method 1: One-Click (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/wineny/claude-daily-commands/main/install.sh | bash
```

### Method 2: Git Clone

```bash
git clone https://github.com/wineny/claude-daily-commands.git
cd claude-daily-commands
chmod +x install.sh
./install.sh
```

### Method 3: Manual

```bash
# Global install (all projects)
mkdir -p ~/.claude/commands
curl -fsSL https://raw.githubusercontent.com/wineny/claude-daily-commands/main/.claude/commands/dailyreviewv2.md -o ~/.claude/commands/dailyreviewv2.md
curl -fsSL https://raw.githubusercontent.com/wineny/claude-daily-commands/main/.claude/commands/todov2.md -o ~/.claude/commands/todov2.md
```

### After Installation

1. **Restart Claude Code completely** (Cmd+Q or Ctrl+Q)
2. Navigate to a Git repository
3. Type `/` to see available commands
4. Try `/dailyreviewv2` or `/todov2`

---

## 🔄 Updating

### Check for Updates

```bash
cd ~/claude-daily-commands
./scripts/update.sh
```

The update script will:
- ✅ Check for new versions
- ✅ Show changelog
- ✅ Ask for confirmation
- ✅ Update commands automatically
- ✅ Remind you to restart Claude Code

### Manual Update

```bash
cd ~/claude-daily-commands
git pull origin main
cp -f .claude/commands/* ~/.claude/commands/
```

**Note**: Restart Claude Code after updating to apply changes.

---

## 🌐 Own It Integration (Beta)

Automatically sync your daily reviews to [Own It](https://github.com/wineny/own-it) backend and track your progress over time!

### Quick Setup

```bash
# 1. Setup API key (one-time)
cd claude-daily-commands
./scripts/setup-ownit.sh

# 2. Use /dailyreview with --sync in Claude Code
/dailyreview --sync           # Today + auto-sync
/dailyreview week --sync      # Last 7 days + auto-sync

# Or sync manually from terminal
./scripts/sync-daily-review.sh
./scripts/sync-daily-review.sh week
```

### Features

- 🔄 **Auto-sync**: Automatically sync daily reviews to Own It backend
- 🔗 **GitHub Integration**: Matches repositories with your GitHub account
- 📊 **Dashboard**: View your progress in Own It web dashboard
- 🔐 **Secure**: API key authentication with bcrypt hashing
- 💾 **Persistent**: All your reviews stored in PostgreSQL database

### Configuration

After running `setup-ownit.sh`, your configuration is saved to:

```
~/.claude-daily-commands/config.json
```

```json
{
  "ownit": {
    "apiKey": "own_it_sk_xxxxxxxxxxxxxxxxxxxxxxxx",
    "apiUrl": "http://localhost:3001"
  }
}
```

### Usage Examples

**In Claude Code:**
```bash
# Review with auto-sync (recommended)
/dailyreview --sync
/dailyreview week --sync

# Review only (no sync)
/dailyreview
/dailyreview week
```

**In Terminal:**
```bash
# Sync today's work
./scripts/sync-daily-review.sh

# Sync yesterday
./scripts/sync-daily-review.sh yesterday

# Sync last 7 days
./scripts/sync-daily-review.sh week

# Local summary only (no sync)
./scripts/sync-daily-review.sh --no-sync
```

### What Gets Synced

- ✅ Commit statistics (count, files, additions, deletions)
- ✅ Full commit timeline with messages and authors
- ✅ File change analysis
- ✅ Main work areas identification
- ✅ Repository information (path, remote URL)

### Graceful Degradation

If sync fails (no API key, server down, etc.), the script will:

1. Show a helpful error message
2. Display local summary anyway
3. Continue working without interruption

**No API key? No problem!** The scripts work locally even without Own It integration.

---

## 🔧 Troubleshooting

### Commands not showing

```bash
# Check if files exist
ls -la ~/.claude/commands/

# Restart Claude Code completely
# (Cmd+Q, not just reload)
```

### "Not a git repo" error

```bash
# Check if you're in a git repository
git status

# Or initialize a new repo
git init
```

### No commits found

```bash
# Check if there are commits today
git log --since="today 00:00" --oneline

# Try yesterday or weekly
/dailyreviewv2 yesterday
/dailyreviewv2 week
```

---

## 🗺️ Roadmap

### v0.2.0 (Current - Beta)
- ✅ `/dailyreviewv2` - 80% shorter, 85% faster
- ✅ `/todov2` - 70% shorter, 60% faster
- ✅ 3-level output modes (default/brief/full)
- ✅ Own It backend integration (API sync)
- 🔄 Beta testing and feedback collection

### v0.3.0 (Next)
- [ ] v2 stabilization and v1 replacement
- [ ] Own It web dashboard (frontend)
- [ ] Multi-language support (English, Japanese)
- [ ] Custom output templates
- [ ] Task agent integration

### v1.0.0 (Future)
- [ ] OAuth2 authentication
- [ ] Full `/portfolio` feature
- [ ] Export to various formats
- [ ] Real-time collaboration features

---

## 🤝 Contributing

Issues and PRs are welcome!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 License

MIT License - Feel free to use!

See [LICENSE](./LICENSE) file for details.

---

## 💬 Support

- **Issues**: [GitHub Issues](https://github.com/wineny/claude-daily-commands/issues)
- **Discussions**: [GitHub Discussions](https://github.com/wineny/claude-daily-commands/discussions)

---

## 🙏 Acknowledgments

- [Claude Code](https://claude.ai/code) - Anthropic's AI coding tool
- All open source contributors

---

**Made with ❤️ for developers who track their daily progress**

⭐ If this project helps you, please give it a star!

---

## 📚 Documentation

- [V2 Test Guide](./V2_TEST_GUIDE.md) - Testing v2 commands
- [V2 Changelog](./V2_CHANGELOG.md) - What's new in v2
- [Examples](./examples/) - Real output examples
- [PRD](./PRD.md) - Product requirements (Korean)
