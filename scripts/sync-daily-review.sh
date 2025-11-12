#!/bin/bash
# sync-daily-review.sh - Sync daily review to Own It backend

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
CONFIG_DIR="$HOME/.claude-daily-commands"
CONFIG_FILE="$CONFIG_DIR/config.json"

# Parse arguments
NO_SYNC=false
TIME_RANGE="today"

for arg in "$@"; do
  case "$arg" in
    --no-sync) NO_SYNC=true ;;
    yesterday|week) TIME_RANGE="$arg" ;;
  esac
done

# Check if in git repository
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo -e "${RED}❌ Not a git repository${NC}"
  echo "💡 Run this command in a git repository"
  exit 1
fi

# Determine time range
case "$TIME_RANGE" in
  yesterday)
    SINCE="yesterday 00:00"
    UNTIL="yesterday 23:59"
    if [[ "$OSTYPE" == "darwin"* ]]; then
      DATE=$(date -v-1d +%Y-%m-%d)
    else
      DATE=$(date -d "yesterday" +%Y-%m-%d)
    fi
    ;;
  week)
    SINCE="7 days ago"
    UNTIL="now"
    DATE=$(date +%Y-%m-%d)
    ;;
  *)
    SINCE="today 00:00"
    UNTIL="now"
    DATE=$(date +%Y-%m-%d)
    ;;
esac

# Collect git data
GIT_LOG=$(git log --since="$SINCE" --until="$UNTIL" \
  --pretty=format:'COMMIT:%H|%ai|%s|%an' \
  --numstat \
  --no-merges 2>/dev/null || true)

if [ -z "$GIT_LOG" ]; then
  echo "📭 No commits found for $DATE"
  exit 0
fi

# Get repository info
REPO_PATH=$(git rev-parse --show-toplevel)
REPO_REMOTE=$(git config --get remote.origin.url 2>/dev/null || echo "")

# Parse git data and create JSON using Python
JSON_DATA=$(python3 << 'PYTHON_EOF'
import sys
import json
from collections import defaultdict

git_log = """__GIT_LOG__"""
repo_path = """__REPO_PATH__"""
repo_remote = """__REPO_REMOTE__"""
review_date = """__DATE__"""

commits = []
stats = {"commits": 0, "files": set(), "additions": 0, "deletions": 0}
file_changes = defaultdict(int)
current_commit = None

for line in git_log.strip().split('\n'):
    if line.startswith('COMMIT:'):
        if current_commit:
            commits.append(current_commit)

        # Parse: COMMIT:sha|datetime|message|author
        parts = line[7:].split('|', 3)
        if len(parts) >= 4:
            current_commit = {
                "sha": parts[0],
                "time": parts[1],
                "message": parts[2],
                "author": parts[3],
                "files": [],
                "additions": 0,
                "deletions": 0
            }
            stats["commits"] += 1
    elif '\t' in line and current_commit:
        # Parse numstat: additions\tdeletions\tfilename
        parts = line.split('\t')
        if len(parts) == 3:
            adds_str, dels_str, filename = parts
            adds = int(adds_str) if adds_str.isdigit() else 0
            dels = int(dels_str) if dels_str.isdigit() else 0

            current_commit["files"].append(filename)
            current_commit["additions"] += adds
            current_commit["deletions"] += dels

            stats["files"].add(filename)
            stats["additions"] += adds
            stats["deletions"] += dels

            file_changes[filename] += 1

# Add last commit
if current_commit:
    commits.append(current_commit)

# Analyze main work areas
main_areas = []
if file_changes:
    dir_changes = defaultdict(int)
    for file, count in file_changes.items():
        dir_name = file.split('/')[0] if '/' in file else 'root'
        dir_changes[dir_name] += count

    # Top 3 directories
    main_areas = sorted(dir_changes.items(), key=lambda x: x[1], reverse=True)[:3]
    main_areas = [area[0] for area in main_areas]

# Build JSON output
output = {
    "date": review_date,
    "stats": {
        "commits": stats["commits"],
        "files": len(stats["files"]),
        "additions": stats["additions"],
        "deletions": stats["deletions"]
    },
    "commits": commits,
    "analysis": {
        "mainAreas": main_areas,
        "fileChanges": dict(file_changes)
    }
}

# Add repository info if available
if repo_path and repo_remote:
    output["repository"] = {
        "path": repo_path,
        "remote": repo_remote
    }

print(json.dumps(output))
PYTHON_EOF
)

# Replace placeholders in Python script
JSON_DATA=$(python3 << PYTHON_EOF
import sys
import json
from collections import defaultdict

git_log = """$GIT_LOG"""
repo_path = """$REPO_PATH"""
repo_remote = """$REPO_REMOTE"""
review_date = """$DATE"""

commits = []
stats = {"commits": 0, "files": set(), "additions": 0, "deletions": 0}
file_changes = defaultdict(int)
current_commit = None

for line in git_log.strip().split('\n'):
    if line.startswith('COMMIT:'):
        if current_commit:
            commits.append(current_commit)

        # Parse: COMMIT:sha|datetime|message|author
        parts = line[7:].split('|', 3)
        if len(parts) >= 4:
            current_commit = {
                "sha": parts[0],
                "time": parts[1],
                "message": parts[2],
                "author": parts[3],
                "files": [],
                "additions": 0,
                "deletions": 0
            }
            stats["commits"] += 1
    elif '\t' in line and current_commit:
        # Parse numstat: additions\tdeletions\tfilename
        parts = line.split('\t')
        if len(parts) == 3:
            adds_str, dels_str, filename = parts
            adds = int(adds_str) if adds_str.isdigit() else 0
            dels = int(dels_str) if dels_str.isdigit() else 0

            current_commit["files"].append(filename)
            current_commit["additions"] += adds
            current_commit["deletions"] += dels

            stats["files"].add(filename)
            stats["additions"] += adds
            stats["deletions"] += dels

            file_changes[filename] += 1

# Add last commit
if current_commit:
    commits.append(current_commit)

# Analyze main work areas
main_areas = []
if file_changes:
    dir_changes = defaultdict(int)
    for file, count in file_changes.items():
        dir_name = file.split('/')[0] if '/' in file else 'root'
        dir_changes[dir_name] += count

    # Top 3 directories
    main_areas = sorted(dir_changes.items(), key=lambda x: x[1], reverse=True)[:3]
    main_areas = [area[0] for area in main_areas]

# Build JSON output
output = {
    "date": review_date,
    "stats": {
        "commits": stats["commits"],
        "files": len(stats["files"]),
        "additions": stats["additions"],
        "deletions": stats["deletions"]
    },
    "commits": commits,
    "analysis": {
        "mainAreas": main_areas,
        "fileChanges": dict(file_changes)
    }
}

# Add repository info if available
if repo_path and repo_remote:
    output["repository"] = {
        "path": repo_path,
        "remote": repo_remote
    }

print(json.dumps(output))
PYTHON_EOF
)

# Extract stats for display
COMMIT_COUNT=$(echo "$JSON_DATA" | python3 -c "import sys, json; print(json.load(sys.stdin)['stats']['commits'])")
FILE_COUNT=$(echo "$JSON_DATA" | python3 -c "import sys, json; print(json.load(sys.stdin)['stats']['files'])")
ADDITIONS=$(echo "$JSON_DATA" | python3 -c "import sys, json; print(json.load(sys.stdin)['stats']['additions'])")
DELETIONS=$(echo "$JSON_DATA" | python3 -c "import sys, json; print(json.load(sys.stdin)['stats']['deletions'])")
MAIN_AREAS=$(echo "$JSON_DATA" | python3 -c "import sys, json; areas = json.load(sys.stdin)['analysis']['mainAreas']; print(', '.join(areas[:2]) if areas else 'N/A')")

# Print local summary header
echo ""
echo "# 📅 Daily Review - $DATE"
echo ""
echo "**${COMMIT_COUNT}개 커밋 | ${FILE_COUNT}개 파일 | +${ADDITIONS}줄 -${DELETIONS}줄**"
echo ""

# Sync to backend (if not disabled)
SYNC_SUCCESS=false
if [ "$NO_SYNC" = false ]; then
  # Check for config file
  if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}⚠️  No API key configured${NC}"
    echo "💡 Run: ./scripts/setup-ownit.sh to configure Own It integration"
    echo ""
  else
    # Load config
    if command -v jq &>/dev/null; then
      API_KEY=$(jq -r '.ownit.apiKey // ""' "$CONFIG_FILE")
      API_URL=$(jq -r '.ownit.apiUrl // "http://localhost:3001"' "$CONFIG_FILE")

      if [ -n "$API_KEY" ]; then
        echo "🔄 Syncing to Own It..."

        # Make API call
        RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/daily-reviews/sync" \
          -H "Authorization: Bearer $API_KEY" \
          -H "Content-Type: application/json" \
          -d "$JSON_DATA")

        # Parse response
        HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
        BODY=$(echo "$RESPONSE" | sed '$d')

        if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
          if echo "$BODY" | python3 -c "import sys, json; exit(0 if json.load(sys.stdin).get('success') else 1)" 2>/dev/null; then
            REVIEW_ID=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['id'])" 2>/dev/null || echo "")
            echo -e "${GREEN}✅ Own It 동기화 완료!${NC}"
            if [ -n "$REVIEW_ID" ]; then
              echo "📊 대시보드에서 확인: ${API_URL}/dashboard/reviews/${REVIEW_ID}"
            fi
            echo ""
            SYNC_SUCCESS=true
          else
            ERROR_MSG=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin).get('message', 'Unknown error'))" 2>/dev/null || echo "Unknown error")
            echo -e "${RED}❌ Own It 동기화 실패: $ERROR_MSG${NC}"
            echo ""
          fi
        else
          echo -e "${RED}❌ Own It 동기화 실패 (HTTP $HTTP_CODE)${NC}"
          echo ""
        fi
      fi
    else
      echo -e "${YELLOW}⚠️  jq not installed, skipping sync${NC}"
      echo "💡 Install jq: brew install jq"
      echo ""
    fi
  fi
fi

# Print commit timeline
echo "## Timeline"
echo ""
echo "$GIT_LOG" | grep '^COMMIT:' | while IFS='|' read -r commit_line; do
  SHA=$(echo "$commit_line" | cut -d'|' -f1 | sed 's/COMMIT://')
  DATETIME=$(echo "$commit_line" | cut -d'|' -f2)
  TIME=$(echo "$DATETIME" | awk '{print $2}' | cut -d':' -f1,2)
  MSG=$(echo "$commit_line" | cut -d'|' -f3)

  # Get main directory for this commit
  MAIN_DIR=$(git show --stat --format="" "$SHA" 2>/dev/null | head -5 | awk '{print $1}' | xargs -I{} dirname {} 2>/dev/null | sort | uniq -c | sort -rn | head -1 | awk '{print $2}' || echo ".")

  echo "[$TIME] $MSG ($MAIN_DIR)"
done

echo ""
echo "💡 주요 작업: $MAIN_AREAS"
echo ""
