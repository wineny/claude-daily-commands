---
allowed-tools: [Bash, Task]
description: "Daily Review with Own It sync (v2 Optimized)"
---

# /dailyreviewv2-sync - Daily Review with Backend Sync

Git 커밋을 분석하고 Own It 백엔드에 자동으로 동기화합니다.

## 핵심 기능
- ✅ 간결한 커밋 요약 (v2 최적화)
- ✅ Own It 백엔드 자동 동기화
- ✅ GitHub 연동 리포지토리 매칭
- ✅ 설정 파일 기반 API 인증

## 사용법
```bash
/dailyreviewv2-sync              # 오늘 작업 + 동기화
/dailyreviewv2-sync yesterday    # 어제 작업 + 동기화
/dailyreviewv2-sync week         # 최근 7일 + 동기화
/dailyreviewv2-sync --no-sync    # 동기화 없이 로컬만
```

## 실행 단계

### 1. Git 저장소 확인 및 시간 범위 결정
```bash
# 저장소 확인
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "❌ Not a git repository"
  exit 1
fi

# 시간 범위 설정
case "$1" in
  yesterday)
    SINCE="yesterday 00:00"
    UNTIL="yesterday 23:59"
    DATE=$(date -v-1d +%Y-%m-%d)
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
```

### 2. Git 데이터 수집 (통합 명령어)
```bash
# 커밋 정보 + 통계 한 번에 수집
GIT_DATA=$(git log --since="$SINCE" --until="$UNTIL" \
  --pretty=format:'COMMIT:%H|%ai|%s|%an' \
  --numstat \
  --no-merges \
  --max-count=50)

if [ -z "$GIT_DATA" ]; then
  echo "📭 No commits found for $DATE"
  exit 0
fi
```

### 3. 리포지토리 정보 수집
```bash
# 로컬 경로
REPO_PATH=$(git rev-parse --show-toplevel)

# 원격 URL (origin)
REPO_REMOTE=$(git config --get remote.origin.url 2>/dev/null || echo "")
```

### 4. 데이터 파싱 및 JSON 생성
```bash
# Python으로 Git 데이터를 JSON으로 변환
python3 << 'EOF'
import sys
import json
import subprocess
from datetime import datetime

# Git 데이터 읽기
git_data = """$GIT_DATA"""

commits = []
stats = {"commits": 0, "files": set(), "additions": 0, "deletions": 0}
file_changes = {}
current_commit = None

for line in git_data.split('\n'):
    if line.startswith('COMMIT:'):
        if current_commit:
            commits.append(current_commit)

        # Parse: COMMIT:sha|date|message|author
        parts = line[7:].split('|', 3)
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
            adds = int(parts[0]) if parts[0].isdigit() else 0
            dels = int(parts[1]) if parts[1].isdigit() else 0
            filename = parts[2]

            current_commit["files"].append(filename)
            current_commit["additions"] += adds
            current_commit["deletions"] += dels

            stats["files"].add(filename)
            stats["additions"] += adds
            stats["deletions"] += dels

            file_changes[filename] = file_changes.get(filename, 0) + 1

if current_commit:
    commits.append(current_commit)

# 주요 작업 영역 분석
main_areas = []
if file_changes:
    # 가장 많이 변경된 디렉토리 찾기
    dir_changes = {}
    for file, count in file_changes.items():
        dir_name = file.split('/')[0] if '/' in file else 'root'
        dir_changes[dir_name] = dir_changes.get(dir_name, 0) + count

    # 상위 3개 디렉토리
    main_areas = sorted(dir_changes.items(), key=lambda x: x[1], reverse=True)[:3]
    main_areas = [area[0] for area in main_areas]

# JSON 생성
output = {
    "date": "$DATE",
    "repository": {
        "path": "$REPO_PATH",
        "remote": "$REPO_REMOTE"
    },
    "stats": {
        "commits": stats["commits"],
        "files": len(stats["files"]),
        "additions": stats["additions"],
        "deletions": stats["deletions"]
    },
    "commits": commits,
    "analysis": {
        "mainAreas": main_areas,
        "fileChanges": file_changes
    }
}

print(json.dumps(output, indent=2))
EOF
```

### 5. Own It 백엔드 동기화
```bash
# API 키 로드
CONFIG_FILE="$HOME/.claude-daily-commands/config.json"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "⚠️  No API key configured"
  echo "💡 Run: /dailyreview-setup to configure Own It integration"
  echo ""
  echo "📊 Showing local summary only..."
  # 로컬 요약 출력 후 종료
  exit 0
fi

API_KEY=$(jq -r '.ownit.apiKey' "$CONFIG_FILE")
API_URL=$(jq -r '.ownit.apiUrl // "http://localhost:3001"' "$CONFIG_FILE")

# --no-sync 플래그 확인
if [[ "$*" == *"--no-sync"* ]]; then
  echo "📊 Local summary mode (no sync)"
  # 로컬 요약만 출력
  exit 0
fi

# API 호출
RESPONSE=$(curl -s -X POST "$API_URL/api/daily-reviews/sync" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d "$JSON_DATA")

# 응답 확인
if echo "$RESPONSE" | jq -e '.success' &>/dev/null; then
  REVIEW_URL=$(echo "$RESPONSE" | jq -r '.data.reviewUrl')
  echo "✅ Synced to Own It"
  echo "🔗 View: $REVIEW_URL"
else
  ERROR_MSG=$(echo "$RESPONSE" | jq -r '.message // "Unknown error"')
  echo "❌ Sync failed: $ERROR_MSG"
  echo ""
  echo "📊 Showing local summary..."
fi
```

### 6. 로컬 요약 출력
```bash
# 간결한 요약 (v2 스타일)
echo ""
echo "# 📅 Daily Review - $DATE"
echo ""
echo "**${COMMIT_COUNT}개 커밋 | ${FILE_COUNT}개 파일 | +${ADDITIONS}줄 -${DELETIONS}줄**"
echo ""

# 커밋 타임라인 (시간 + 메시지 + 주요 디렉토리)
echo "$GIT_DATA" | grep '^COMMIT:' | while read -r line; do
  SHA=$(echo "$line" | cut -d'|' -f1 | cut -d':' -f2)
  TIME=$(echo "$line" | cut -d'|' -f2 | cut -d' ' -f2 | cut -d':' -f1,2)
  MSG=$(echo "$line" | cut -d'|' -f3)

  # 해당 커밋의 주요 디렉토리 찾기
  MAIN_DIR=$(git show --stat --format="" "$SHA" | head -5 | awk '{print $1}' | xargs dirname | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')

  echo "[$TIME] $MSG ($MAIN_DIR)"
done

echo ""
echo "💡 주요 작업: ${MAIN_AREAS[0]}, ${MAIN_AREAS[1]}"
```

## 설정 파일 형식

`~/.claude-daily-commands/config.json`:
```json
{
  "ownit": {
    "apiKey": "own_it_sk_xxxxxxxxxxxxxxxxxxxxxxxx",
    "apiUrl": "http://localhost:3001"
  }
}
```

## 에러 처리

**API 키 없음**:
```
⚠️  No API key configured
💡 Run: /dailyreview-setup to configure Own It integration

📊 Showing local summary only...
[로컬 요약 출력]
```

**동기화 실패**:
```
❌ Sync failed: Invalid API key

📊 Showing local summary...
[로컬 요약 출력]
```

**Git 저장소 아님**:
```
❌ Not a git repository
💡 Run this command in a git repository
```

## 구현 가이드

### 핵심 전략
1. **데이터 무결성**: Git 데이터를 정확하게 JSON으로 변환
2. **Graceful Degradation**: 동기화 실패 시 로컬 요약 표시
3. **설정 분리**: API 키를 별도 설정 파일로 관리
4. **에러 복구**: 모든 에러 케이스에서 유용한 정보 제공

### 보안 고려사항
- API 키는 파일 시스템에 저장 (권한 600)
- Bearer 토큰 방식 인증
- HTTPS 권장 (프로덕션)

### 성능 목표
- ✅ 데이터 수집: 1회 Git 명령
- ✅ JSON 변환: Python 파싱 (<1초)
- ✅ API 호출: 비동기 가능 (선택적)
- ✅ 전체 실행: <5초

## 주의사항
- Git 데이터가 없으면 로컬 요약만 표시
- API 동기화는 선택적 (--no-sync로 비활성화)
- 설정 파일이 없으면 setup 안내 후 로컬 모드
- JSON 변환 실패 시 raw 데이터라도 전송 시도

---

**v2 + Sync**: 간결한 출력 + 자동 백엔드 동기화 + Graceful Degradation
