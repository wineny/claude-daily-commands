#!/bin/bash
# sync-daily-review.sh - Sync daily review to Own It backend

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

# Determine sync mode (authenticated vs anonymous)
MODE="anonymous"
API_KEY=""
API_URL="http://localhost:4000"

if [ -f "$CONFIG_FILE" ] && command -v jq &>/dev/null; then
  API_KEY=$(jq -r '.api_key // ""' "$CONFIG_FILE" 2>/dev/null || echo "")
  CUSTOM_API_URL=$(jq -r '.api_url // ""' "$CONFIG_FILE" 2>/dev/null || echo "")

  if [ -n "$CUSTOM_API_URL" ]; then
    API_URL="$CUSTOM_API_URL"
  fi

  if [ -n "$API_KEY" ]; then
    MODE="authenticated"
  fi
fi

# Sync to backend (if not disabled)
SYNC_SUCCESS=false
REVIEW_URL=""

if [ "$NO_SYNC" = false ]; then
  if [ "$MODE" = "authenticated" ]; then
    # ============================================
    # Authenticated Mode (기존 로직)
    # ============================================
    echo -e "${CYAN}🔄 Own It에 동기화 중... (인증 모드)${NC}"

    ENDPOINT="$API_URL/api/daily-reviews/sync"

    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$ENDPOINT" \
      -H "Authorization: Bearer $API_KEY" \
      -H "Content-Type: application/json" \
      -d "$JSON_DATA")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
      if echo "$BODY" | python3 -c "import sys, json; exit(0 if json.load(sys.stdin).get('success') else 1)" 2>/dev/null; then
        REVIEW_ID=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['id'])" 2>/dev/null || echo "")
        echo -e "${GREEN}✅ Own It 동기화 완료!${NC}"
        if [ -n "$REVIEW_ID" ]; then
          REVIEW_URL="${API_URL}/dashboard/reviews/${REVIEW_ID}"
          echo "📊 대시보드: ${REVIEW_URL}"
        fi
        echo ""
        SYNC_SUCCESS=true
      else
        ERROR_MSG=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin).get('message', 'Unknown error'))" 2>/dev/null || echo "Unknown error")
        echo -e "${RED}❌ 동기화 실패: $ERROR_MSG${NC}"
        echo ""
      fi
    else
      echo -e "${RED}❌ 동기화 실패 (HTTP $HTTP_CODE)${NC}"
      echo ""
    fi

  else
    # ============================================
    # Anonymous Mode (새로운 로직)
    # ============================================
    echo -e "${CYAN}🔄 Own It에 업로드 중... (익명 모드)${NC}"

    ENDPOINT="$API_URL/api/anonymous-reviews"

    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$ENDPOINT" \
      -H "Content-Type: application/json" \
      -d "$JSON_DATA")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
      if echo "$BODY" | python3 -c "import sys, json; exit(0 if json.load(sys.stdin).get('success') else 1)" 2>/dev/null; then
        REVIEW_URL=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['url'])" 2>/dev/null || echo "")
        EXPIRES_AT=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['expiresAt'])" 2>/dev/null || echo "")

        echo -e "${GREEN}✅ 익명 리뷰 생성 완료!${NC}"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${YELLOW}💡 웹에서 예쁘게 보고 싶으신가요?${NC}"
        echo ""
        echo "브라우저에서 타임라인과 통계를 확인할 수 있습니다:"
        echo -e "${BLUE}${REVIEW_URL}${NC}"
        echo ""
        echo -e "${YELLOW}⚠️  주의: 익명 리뷰는 24시간 후 자동 삭제됩니다${NC}"
        if [ -n "$EXPIRES_AT" ]; then
          echo "   만료 시간: $EXPIRES_AT"
        fi
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        # 브라우저 오픈 여부 물어보기
        read -p "지금 브라우저에서 보시겠습니까? (Y/n) " -n 1 -r
        echo ""

        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
          echo -e "${CYAN}🌐 브라우저 열기...${NC}"

          # OS별 브라우저 오픈
          if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            open "$REVIEW_URL"
          elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            if command -v xdg-open &>/dev/null; then
              xdg-open "$REVIEW_URL"
            else
              echo -e "${YELLOW}⚠️  xdg-open을 찾을 수 없습니다. 직접 방문하세요:${NC}"
              echo "$REVIEW_URL"
            fi
          elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
            # Windows Git Bash
            start "$REVIEW_URL"
          else
            echo -e "${YELLOW}⚠️  OS를 인식할 수 없습니다. 직접 방문하세요:${NC}"
            echo "$REVIEW_URL"
          fi

          echo ""
          echo -e "${GREEN}✅ 브라우저가 열렸습니다!${NC}"
          echo ""
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo -e "${CYAN}💼 계속 이렇게 보고 싶으신가요?${NC}"
          echo ""
          echo "GitHub로 로그인하면:"
          echo "  ✓ 무제한 저장"
          echo "  ✓ 언제든 확인 가능"
          echo "  ✓ 자동 포트폴리오 생성"
          echo ""
          echo -e "회원가입: ${BLUE}${API_URL}${NC}"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo ""
        fi

        SYNC_SUCCESS=true
      else
        ERROR_MSG=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin).get('error', 'Unknown error'))" 2>/dev/null || echo "Unknown error")
        echo -e "${RED}❌ 업로드 실패: $ERROR_MSG${NC}"
        echo ""
      fi
    else
      echo -e "${RED}❌ 업로드 실패 (HTTP $HTTP_CODE)${NC}"
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
