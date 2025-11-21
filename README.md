# 📊 Own It - Daily Review CLI Integration

> Sync your Git commits to Own It platform with AI-powered insights

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude-Code-blue.svg)](https://claude.ai/code)

---

## 🚀 One-Click Install

```bash
curl -fsSL https://raw.githubusercontent.com/wineny/claude-daily-commands/main/install.sh | bash
```

**Then restart Claude Code (Cmd+Q) and you're ready to go!**

---

## 📌 What is this?

**Own It Daily Review CLI** automatically syncs your Git commit data to the Own It platform, providing:

- 📊 **Automatic Git Analysis** - Parse commit history, stats, and changes
- 🤖 **AI-Powered Reports** - Claude API generates insightful daily summaries
- 🌐 **Web Dashboard** - Beautiful visualization on own-it.dev
- 🔒 **Anonymous Mode** - Try without signup (24hr expiry)
- 🔑 **Authenticated Mode** - Permanent storage with API key

---

## ✨ Features

### /dailyreview-sync Command

**Anonymous Mode (No API Key)**
- Create temporary review (24hr expiry)
- View in browser immediately
- Beautiful web UI with signup CTAs
- No commitment required

**Authenticated Mode (With API Key)**
- Permanent storage in Own It platform
- Link to GitHub repository
- Unlimited reviews
- Portfolio generation

### AI Report Generation (Optional)

Powered by Claude API, generates:
- **Summary**: Overall development focus
- **Key Achievements**: Main accomplishments
- **Technical Highlights**: Notable patterns and improvements
- **Recommendations**: Actionable next steps

---

## 📖 Quick Start

### 1. Install

```bash
# One-click installation
curl -fsSL https://raw.githubusercontent.com/wineny/claude-daily-commands/main/install.sh | bash

# Or clone and install locally
git clone https://github.com/wineny/claude-daily-commands.git
cd claude-daily-commands
bash install.sh
```

### 2. Setup Own It Integration

```bash
~/.claude-daily-commands/scripts/setup-ownit.sh
```

**Interactive Setup:**
```
Enter your Own It API key: own_it_sk_abc123...
Enter API URL (default: http://localhost:4000): [Enter]
Enter Claude API key (or press Enter to skip): sk-ant-xxx...
```

### 3. Restart Claude Code

- **macOS**: Cmd+Q, then reopen
- **Windows/Linux**: Ctrl+Q, then reopen

### 4. Use the Command

```bash
# In any Git repository
/dailyreview-sync
```

---

## 🎯 Usage Examples

### First Time (Anonymous Mode)

```bash
cd /your/project
/dailyreview-sync
```

**Output:**
```
# 📅 Daily Review - 2025-11-13

**3개 커밋 | 12개 파일 | +245줄 -87줄**

🤖 AI 리포트 생성 중...
✅ AI 리포트 생성 완료

🔄 Own It에 업로드 중... (익명 모드)
✅ 익명 리뷰 생성 완료!

📊 임시 링크: http://localhost:4000/reviews/abc123xyz
⏰ 24시간 후 자동 삭제

지금 브라우저에서 보시겠습니까? (Y/n) y
```

**Browser opens automatically** → See beautiful review → Signup CTA

### After Signup (Authenticated Mode)

```bash
# Configure API key
~/.claude-daily-commands/scripts/setup-ownit.sh

# Then sync
/dailyreview-sync
```

**Output:**
```
# 📅 Daily Review - 2025-11-13

**3개 커밋 | 12개 파일 | +245줄 -87줄**

🤖 AI 리포트 생성 중...
✅ AI 리포트 생성 완료

🔄 Own It에 동기화 중... (인증 모드)
✅ Own It 동기화 완료!

📊 대시보드: http://localhost:4000/dashboard/reviews/456
```

---

## 🤖 AI Report Setup

### Get Claude API Key

1. Visit [Anthropic Console](https://console.anthropic.com/)
2. Sign in or create account
3. Generate API key
4. Copy key (starts with `sk-ant-`)

### Configure

```bash
~/.claude-daily-commands/scripts/setup-ownit.sh
```

When prompted:
```
🤖 Claude AI Integration (Optional)
Enter Claude API key (or press Enter to skip): sk-ant-api03-xxx...
```

### Cost

- Model: Claude 3.5 Sonnet
- ~$0.01-0.02 per report
- Monthly: ~$0.20-0.40 (20 working days)

**See [AI_REPORT_GUIDE.md](AI_REPORT_GUIDE.md) for detailed setup.**

---

## 🔧 Configuration

### Config File Location

```bash
~/.claude-daily-commands/config.json
```

### Structure

```json
{
  "ownit_api_key": "own_it_sk_abc123...",
  "ownit_api_url": "http://localhost:4000",
  "claude_api_key": "sk-ant-api03-xxx..."
}
```

### Update Configuration

```bash
~/.claude-daily-commands/scripts/setup-ownit.sh
```

---

## 📂 Project Structure

```
claude-daily-commands/
├── .claude/
│   └── commands/
│       ├── dailyreview-sync.md     # Slash command definition
│       └── _archived/              # Old commands
├── scripts/
│   ├── sync-daily-review.sh        # Main sync script
│   └── setup-ownit.sh              # Setup script
├── install.sh                      # One-click installer
├── AI_REPORT_GUIDE.md              # AI report setup guide
├── BACKEND_FRONTEND_INTEGRATION.md # Backend/Frontend guide
└── README.md                       # This file
```

---

## 🎨 Backend & Frontend Integration

The CLI now sends `aiReport` field with daily review data.

**Backend needs to:**
- Add `ai_report` field to database schema (text)
- Accept `aiReport` in API endpoints
- Store and return the report

**Frontend needs to:**
- Create `AIReportCard` component
- Display AI report in review detail pages
- Add copy button and markdown rendering

**See [BACKEND_FRONTEND_INTEGRATION.md](BACKEND_FRONTEND_INTEGRATION.md) for implementation details.**

---

## 📖 Documentation

- **[AI_REPORT_GUIDE.md](AI_REPORT_GUIDE.md)** - Complete AI report setup and usage guide
- **[BACKEND_FRONTEND_INTEGRATION.md](BACKEND_FRONTEND_INTEGRATION.md)** - Backend/Frontend integration guide
- **[TEST_FLOW.md](TEST_FLOW.md)** - Testing flow and scenarios

---

## 🔒 Privacy & Security

### Data Handling

- **Git metadata only**: Commit messages, file names, stats (no code content)
- **Secure storage**: API keys in `~/.claude-daily-commands/config.json` with `chmod 600`
- **HTTPS encryption**: All API calls encrypted
- **No persistence**: Claude API doesn't store analysis after response

### Anonymous Reviews

- 24-hour expiry automatically
- No personal data required
- Can be deleted manually

---

## 🛠️ Troubleshooting

### "No commits found"

**Problem**: No Git commits to analyze

**Solutions:**
```bash
# Check if in Git repository
git status

# Check commits exist
git log --since="today 00:00"

# Try different date range
/dailyreview-sync yesterday
/dailyreview-sync week
```

### "API key not recognized"

**Problem**: Own It API key not configured correctly

**Solutions:**
```bash
# Re-run setup
~/.claude-daily-commands/scripts/setup-ownit.sh

# Verify config
cat ~/.claude-daily-commands/config.json

# Check key format (should start with own_it_sk_)
```

### "AI 리포트 생성 실패"

**Problem**: Claude API call failed

**Solutions:**
```bash
# Check Claude API key
cat ~/.claude-daily-commands/config.json | grep claude_api_key

# Verify key is valid at console.anthropic.com

# Check internet connection

# Note: Sync continues without AI report if this fails
```

### "Connection refused"

**Problem**: Own It backend not running

**Solutions:**
```bash
# Start Own It backend
cd /path/to/own-it
pnpm dev

# Check if running on correct port
curl http://localhost:4000/health

# Update API URL if needed
~/.claude-daily-commands/scripts/setup-ownit.sh
```

---

## 🚦 Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    /dailyreview-sync                        │
└─────────────────────────────────────────────────────────────┘
                              ↓
                    Check API Key Config
                              ↓
              ┌───────────────┴───────────────┐
              ↓                               ↓
        No API Key                      API Key Found
     (Anonymous Mode)                 (Authenticated Mode)
              ↓                               ↓
    ┌─────────────────────┐         ┌─────────────────────┐
    │ 1. Parse Git commits│         │ 1. Parse Git commits│
    │ 2. Generate AI report│        │ 2. Generate AI report│
    │ 3. Create temp review│        │ 3. Sync to account  │
    │ 4. Open browser     │         │ 4. Link to repo     │
    │ 5. Show signup CTA  │         │ 5. Permanent storage│
    └─────────────────────┘         └─────────────────────┘
              ↓                               ↓
        Expires in 24h                 Stored forever
              ↓                               ↓
      User signs up? ──────────────→  Continue using
              │                          authenticated
              NO
              ↓
         Data deleted
```

---

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details

---

## 🙏 Acknowledgments

- **Claude Code** - Custom slash commands platform
- **Anthropic** - Claude API for AI-powered reports
- **Own It Platform** - Backend and frontend infrastructure

---

## 🔗 Links

- **GitHub**: [github.com/wineny/claude-daily-commands](https://github.com/wineny/claude-daily-commands)
- **Issues**: [github.com/wineny/claude-daily-commands/issues](https://github.com/wineny/claude-daily-commands/issues)
- **Own It**: [own-it.dev](https://own-it.dev) (when deployed)

---

**Created with ❤️ by [wineny](https://github.com/wineny)**
