# 🔗 Own It Integration Guide

Complete guide for setting up and using Claude Daily Commands with Own It backend integration.

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Backend Setup](#backend-setup)
4. [CLI Setup](#cli-setup)
5. [Usage Examples](#usage-examples)
6. [Claude Code Integration](#claude-code-integration)
7. [API Reference](#api-reference)
8. [Troubleshooting](#troubleshooting)

---

## 🏗️ Architecture Overview

```
┌─────────────────────┐
│  Claude Code CLI    │
│  (Local Machine)    │
└──────────┬──────────┘
           │ HTTP POST /api/daily-reviews/sync
           │ Authorization: Bearer own_it_sk_***
           │
           ▼
┌─────────────────────┐
│  Own It Backend     │
│  (Express.js)       │
├─────────────────────┤
│ • API Key Auth      │
│ • Daily Reviews     │
│ • GitHub Integration│
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  PostgreSQL DB      │
├─────────────────────┤
│ • daily_reviews     │
│ • user_api_keys     │
│ • github_repos      │
└─────────────────────┘
```

### Data Flow

1. **Git Analysis**: CLI analyzes local git commits
2. **JSON Creation**: Parse commits into structured JSON
3. **API Authentication**: Bearer token with API key
4. **Repository Matching**: Match git remote with GitHub repos
5. **Upsert Review**: Create or update daily review
6. **Response**: Return review URL and stats

---

## 📦 Prerequisites

### Backend Requirements

- Node.js 18+ and pnpm
- PostgreSQL 14+
- Own It backend running (default: http://localhost:3001)

### CLI Requirements

- Bash shell (macOS/Linux)
- Git repository
- Python 3.6+ (for JSON parsing)
- curl (for API calls)
- jq (for JSON processing)

---

## 🚀 Backend Setup

### 1. Database Migration

The backend includes migration `0003_add_daily_reviews_and_api_keys.sql`:

```bash
cd own-it/apps/api
pnpm db:migrate
```

**Created Tables:**
- `daily_reviews`: Stores synced daily work reviews
- `user_api_keys`: Stores CLI authentication keys

### 2. Start Backend Server

```bash
cd own-it/apps/api
pnpm dev
```

Server should be running on http://localhost:3001

### 3. Generate API Key

**Option A: Via Web Dashboard (Coming Soon)**
```
1. Open http://localhost:3000
2. Navigate to Settings → API Keys
3. Click "Generate New API Key"
4. Copy the key (starts with own_it_sk_)
```

**Option B: Via Database (Manual)**
```sql
-- Generate API key manually
INSERT INTO user_api_keys (user_id, key_hash, key_prefix, name, scopes)
VALUES (
  'your-user-id',
  '$2b$10$...',  -- bcrypt hash of your key
  'own_it_sk_abc123...',
  'My CLI Key',
  ARRAY['read:daily-reviews', 'write:daily-reviews']
);
```

---

## 🛠️ CLI Setup

### 1. Install Scripts

The integration scripts are in `scripts/`:

```bash
cd claude-daily-commands

# Make scripts executable
chmod +x scripts/setup-ownit.sh
chmod +x scripts/sync-daily-review.sh
```

### 2. Configure API Key

```bash
./scripts/setup-ownit.sh
```

**Interactive Setup:**
```
🔑 Own It API Key Setup

To get your API key:
1. Go to Own It dashboard: http://localhost:3000
2. Navigate to Settings → API Keys
3. Click 'Generate New API Key'
4. Copy the key (starts with 'own_it_sk_')

Enter your API key: own_it_sk_abc123def456...

Enter API URL (default: http://localhost:3001):

✅ Configuration saved successfully

🧪 Testing connection...

✅ Connection successful!

🎉 You're all set!
```

**Configuration File:**
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

---

## 📖 Usage Examples

### Basic Sync

```bash
# Sync today's work
./scripts/sync-daily-review.sh
```

**Output:**
```markdown
# 📅 Daily Review - 2025-11-12

**3개 커밋 | 12개 파일 | +342줄 -78줄**

🔄 Syncing to Own It...
✅ Synced to Own It
🔗 View: http://localhost:3001/dashboard/reviews/uuid-here

## Timeline

[14:32] feat: Add API key middleware (src/middlewares)
[15:45] feat: Create daily reviews service (src/services)
[16:20] feat: Implement sync endpoints (src/routes)

💡 주요 작업: src/middlewares, src/services
```

### Time Range Options

```bash
# Yesterday's work
./scripts/sync-daily-review.sh yesterday

# Last 7 days
./scripts/sync-daily-review.sh week

# Local summary only (no sync)
./scripts/sync-daily-review.sh --no-sync
```

### Batch Sync Multiple Days

```bash
# Sync last 7 days (creates/updates 7 reviews)
./scripts/sync-daily-review.sh week
```

---

## 🎯 Claude Code Integration

### Using /dailyreview with --sync

The `/dailyreview` command in Claude Code now supports automatic synchronization to Own It!

**Usage:**
```bash
# Regular review (screen output only)
/dailyreview

# With auto-sync
/dailyreview --sync

# Yesterday with sync
/dailyreview yesterday --sync

# Last 7 days with sync
/dailyreview week --sync
```

**How it works:**

1. `/dailyreview --sync` generates the review report
2. Displays the report in Claude Code
3. Automatically calls `sync-daily-review.sh` in the background
4. Shows sync status (success/failure)

**Output example:**
```markdown
# 📅 Daily Review - 2025-11-12

**9개 커밋 | 21개 파일 | +3972줄 -351줄**

🔄 Syncing to Own It...
✅ Own It 동기화 완료!
📊 대시보드에서 확인: http://localhost:4000/dashboard/reviews/uuid

## Timeline
[23:12] fix: Enhance curl installation process (.claude)
[23:09] fix: Handle stdin in curl pipe installation (.)
...
```

**Setup Required:**

Before using `--sync`, you must configure your API key:

```bash
cd ~/claude-daily-commands
./scripts/setup-ownit.sh
```

**Graceful Degradation:**

- If API key not configured → Shows setup instructions
- If Own It server is down → Shows error, but displays local report anyway
- If sync fails → Shows error message, continues with local report

**Benefits:**

✅ **Seamless workflow**: Review and sync in one command
✅ **Immediate feedback**: See sync status instantly
✅ **Non-blocking**: Works offline, just shows local report
✅ **Flexible**: Choose when to sync with `--sync` flag

---

## 🔌 API Reference

### POST /api/daily-reviews/sync

Create or update a daily review.

**Authentication:**
```
Authorization: Bearer own_it_sk_xxxxxxxxxxxxxxxxxxxxxxxx
```

**Request Body:**
```json
{
  "date": "2025-11-12",
  "repository": {
    "path": "/Users/username/project",
    "remote": "https://github.com/owner/repo.git"
  },
  "stats": {
    "commits": 3,
    "files": 12,
    "additions": 342,
    "deletions": 78
  },
  "commits": [
    {
      "sha": "abc123...",
      "time": "2025-11-12 14:32:15 +0900",
      "message": "feat: Add API key middleware",
      "author": "Developer Name",
      "files": ["src/middlewares/api-key.middleware.ts"],
      "additions": 85,
      "deletions": 12
    }
  ],
  "analysis": {
    "mainAreas": ["src/middlewares", "src/services", "src/routes"],
    "fileChanges": {
      "src/middlewares/api-key.middleware.ts": 1,
      "src/services/daily-reviews.service.ts": 2
    }
  }
}
```

**Response (Success):**
```json
{
  "success": true,
  "data": {
    "id": "uuid-here",
    "reviewUrl": "http://localhost:3001/dashboard/reviews/uuid-here",
    "stats": {
      "commits": 3,
      "files": 12,
      "additions": 342,
      "deletions": 78
    },
    "isNewReview": false
  }
}
```

**Response (Error):**
```json
{
  "success": false,
  "message": "Invalid API key",
  "error": "Unauthorized"
}
```

### GET /api/daily-reviews

Get paginated list of daily reviews.

**Authentication:** JWT (web) or API Key (CLI)

**Query Parameters:**
- `limit`: Number of results (default: 30)
- `offset`: Pagination offset (default: 0)
- `repositoryId`: Filter by repository (optional)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "userId": "user-uuid",
      "repositoryId": "repo-uuid",
      "reviewDate": "2025-11-12",
      "totalCommits": 3,
      "totalFiles": 12,
      "linesAdded": 342,
      "linesDeleted": 78,
      "commits": [...],
      "mainWorkAreas": ["src/middlewares", "src/services"],
      "createdAt": "2025-11-12T05:32:00Z",
      "updatedAt": "2025-11-12T07:20:00Z"
    }
  ]
}
```

### GET /api/daily-reviews/:id

Get a single daily review by ID.

### GET /api/daily-reviews/stats

Get aggregate statistics.

**Response:**
```json
{
  "success": true,
  "data": {
    "totalReviews": 45,
    "totalCommits": 234,
    "totalFiles": 1205,
    "totalLinesAdded": 15432,
    "totalLinesDeleted": 7821
  }
}
```

---

## 🐛 Troubleshooting

### Connection Failed

**Symptom:**
```
❌ Sync failed (HTTP 000)
```

**Solutions:**
1. Check if backend is running: `curl http://localhost:3001/health`
2. Verify API URL in config: `cat ~/.claude-daily-commands/config.json`
3. Check network connectivity

### Invalid API Key

**Symptom:**
```
❌ Sync failed: Invalid API key
```

**Solutions:**
1. Verify key format starts with `own_it_sk_`
2. Check key is active in database:
   ```sql
   SELECT * FROM user_api_keys WHERE is_active = true;
   ```
3. Regenerate API key if needed

### No Commits Found

**Symptom:**
```
📭 No commits found for 2025-11-12
```

**Solutions:**
1. Check git log: `git log --since="today 00:00" --oneline`
2. Try different time range: `./scripts/sync-daily-review.sh yesterday`
3. Verify you're in a git repository: `git status`

### Repository Not Matched

**Symptom:**
Review synced but `repositoryId` is null in database.

**Solutions:**
1. Check git remote: `git config --get remote.origin.url`
2. Verify repository exists in GitHub App installation
3. Check repository fullName format: `owner/repo`

### Permission Denied

**Symptom:**
```
bash: ./scripts/sync-daily-review.sh: Permission denied
```

**Solution:**
```bash
chmod +x scripts/sync-daily-review.sh
chmod +x scripts/setup-ownit.sh
```

### jq Not Found

**Symptom:**
```
⚠️  jq not installed, skipping sync
```

**Solution:**
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# Fedora
sudo dnf install jq
```

---

## 🔒 Security Considerations

### API Key Storage

- Config file permissions: `chmod 600 ~/.claude-daily-commands/config.json`
- Never commit config file to git
- Add to `.gitignore`: `~/.claude-daily-commands/`

### API Key Rotation

```bash
# 1. Generate new key in dashboard
# 2. Update config
./scripts/setup-ownit.sh

# 3. Revoke old key in dashboard or database
UPDATE user_api_keys SET is_active = false WHERE key_prefix = 'old_prefix';
```

### Production Deployment

For production use:

1. **Use HTTPS**: Update `apiUrl` to `https://your-domain.com`
2. **Environment Variables**: Store keys in environment, not config file
3. **Key Expiration**: Set `expires_at` for API keys
4. **Rate Limiting**: Implement rate limits on API endpoints
5. **Audit Logging**: Track API key usage with `last_used_at`

---

## 📊 Database Schema Reference

### daily_reviews

| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| user_id | uuid | Foreign key to users |
| repository_id | uuid | Foreign key to github_repositories (nullable) |
| review_date | date | Date of review (YYYY-MM-DD) |
| total_commits | integer | Number of commits |
| total_files | integer | Number of files changed |
| lines_added | integer | Total lines added |
| lines_deleted | integer | Total lines deleted |
| commits | jsonb | Array of commit objects |
| main_work_areas | jsonb | Array of main directories |
| file_changes | jsonb | Object of file change counts |
| repository_path | jsonb | Local repository path |
| repository_remote | jsonb | Git remote URL |
| created_at | timestamp | Creation timestamp |
| updated_at | timestamp | Last update timestamp |

**Unique Constraint:** (user_id, repository_id, review_date)

### user_api_keys

| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| user_id | uuid | Foreign key to users |
| key_hash | text | bcrypt hash of API key |
| key_prefix | text | First 18 chars (own_it_sk_...) |
| name | text | User-friendly name |
| scopes | text[] | Permission scopes array |
| is_active | boolean | Active status |
| revoked_at | timestamp | Revocation timestamp |
| expires_at | timestamp | Expiration timestamp |
| last_used_at | timestamp | Last usage timestamp |
| last_used_ip | text | Last client IP |
| created_at | timestamp | Creation timestamp |
| updated_at | timestamp | Last update timestamp |

---

## 🎯 Next Steps

1. ✅ Backend API complete
2. ✅ CLI sync scripts complete
3. ⏳ Frontend dashboard (Phase 3)
4. ⏳ API key management UI
5. ⏳ Review visualization charts
6. ⏳ Export and sharing features

---

## 📚 Additional Resources

- [Backend API Source](../own-it/apps/api/src/)
- [CLI Scripts Source](./scripts/)
- [Database Migrations](../own-it/apps/api/src/db/migrations/)
- [Example Outputs](./examples/)

---

**Questions or Issues?**

- [GitHub Issues](https://github.com/wineny/claude-daily-commands/issues)
- [GitHub Discussions](https://github.com/wineny/claude-daily-commands/discussions)
