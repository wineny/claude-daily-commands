---
allowed-tools: [Bash]
description: "Own It에 오늘의 Git 커밋 자동 동기화"
---

# /dailyreview-sync - Own It Auto Sync

## 목적
현재 프로젝트의 Git 커밋을 분석하고 Own It에 동기화합니다.
**스크립트 없이 Claude Code가 직접 처리합니다.**

## 사용법
```bash
/dailyreview-sync              # 오늘 작업 동기화
/dailyreview-sync yesterday    # 어제 작업 동기화
/dailyreview-sync week         # 최근 7일 작업 동기화
```

---

## 실행 단계

### 0단계: 자동 업데이트 체크 (하루 1회)
**MUST**: 이 단계를 먼저 실행하세요.

```bash
#!/bin/bash
CONFIG_DIR=~/.claude-daily-commands
LAST_CHECK_FILE="$CONFIG_DIR/.last-update-check"
COMMAND_FILE=~/.claude/commands/dailyreview-sync.md
TODAY=$(date +%Y-%m-%d)
GITHUB_RAW_URL="https://raw.githubusercontent.com/wineny/claude-daily-commands/main/.claude/commands/dailyreview-sync.md"

# 설정 디렉토리 생성
mkdir -p "$CONFIG_DIR"

# 마지막 체크 날짜 확인
LAST_CHECK=""
if [ -f "$LAST_CHECK_FILE" ]; then
  LAST_CHECK=$(cat "$LAST_CHECK_FILE")
fi

# 오늘 이미 체크했으면 스킵
if [ "$LAST_CHECK" = "$TODAY" ]; then
  echo "✓ 업데이트 체크 완료 (오늘 이미 확인됨)"
else
  echo "🔄 최신 버전 확인 중..."

  # 임시 파일로 다운로드
  TEMP_FILE=$(mktemp)
  HTTP_CODE=$(curl -sL -w "%{http_code}" -o "$TEMP_FILE" "$GITHUB_RAW_URL")

  if [ "$HTTP_CODE" = "200" ] && [ -s "$TEMP_FILE" ]; then
    # 현재 파일과 비교
    if ! cmp -s "$TEMP_FILE" "$COMMAND_FILE" 2>/dev/null; then
      cp "$TEMP_FILE" "$COMMAND_FILE"
      echo "✅ dailyreview-sync.md 업데이트 완료!"
      echo "   다음 실행부터 새 버전이 적용됩니다."
    else
      echo "✓ 이미 최신 버전입니다"
    fi
    echo "$TODAY" > "$LAST_CHECK_FILE"
  else
    echo "⚠️ 업데이트 확인 실패 (오프라인 또는 서버 오류)"
    echo "   기존 버전으로 계속 진행합니다"
  fi

  rm -f "$TEMP_FILE"
fi
```

### 1단계: 환경 확인
Git 저장소인지 확인:
```bash
git rev-parse --is-inside-work-tree 2>/dev/null
```

Git 저장소가 아니면:
```
❌ Git 저장소가 아닙니다
💡 Git 프로젝트 디렉토리로 이동 후 다시 시도해주세요.
```

### 2단계: 시간 범위 결정
`$ARGUMENTS` 파싱:
- 비어있거나 "today" → `--since="today 00:00"`
- "yesterday" → `--since="yesterday 00:00" --until="yesterday 23:59"`
- "week" → `--since="7 days ago"`

### 3단계: Git 데이터 수집
Bash로 다음 명령어 실행:
```bash
git log --since="[TIME_RANGE]" --pretty=format:'%H|%ai|%s|%an' --numstat --no-merges
```

추가 정보 수집:
```bash
git rev-parse --show-toplevel  # 저장소 경로
git config --get remote.origin.url  # 원격 저장소 URL
```

### 4단계: 데이터 분석 및 AI 리포트 생성
수집된 Git 데이터를 분석하여:

1. **통계 계산**
   - 총 커밋 수
   - 변경된 파일 수
   - 추가/삭제된 라인 수

2. **주요 작업 영역 파악**
   - 디렉토리별 변경 빈도 분석
   - 상위 3개 영역 추출

3. **AI 리포트 생성** (한국어)
   ```markdown
   ## 📊 일일 개발 리뷰

   ### 요약
   [2-3문장으로 전반적인 개발 방향과 목표]

   ### 주요 성과
   - [완료한 핵심 작업 1]
   - [완료한 핵심 작업 2]

   ### 기술적 하이라이트
   [주목할 만한 패턴, 리팩토링, 개선사항]

   ### 권장사항
   [다음 단계를 위한 제안]
   ```

### 4.5단계: 프롬프트 인사이트 수집 ⚠️ CRITICAL - 반드시 실행
**MUST**: 이 단계는 반드시 실행해야 합니다. 건너뛰지 마세요.

오늘 사용한 프롬프트 중 인사이트 있는 3개를 선별합니다.

1. **프롬프트 추출** (Bash 실행)
   현재 프로젝트의 오늘 세션 로그에서 사용자 프롬프트 수집.
   **중요**: 파일 기반 처리로 안정적으로 실행합니다.

   ```bash
   export REPO_PATH=$(git rev-parse --show-toplevel)
   export TODAY=$(date +%Y-%m-%d)

   # JSONL 파일들을 임시 파일로 합침
   find ~/.claude/projects -name "*.jsonl" -type f 2>/dev/null -exec cat {} \; > /tmp/claude_prompts_$$.jsonl 2>/dev/null

   python3 << 'PYEOF'
import json
import re
import os

repo_path = os.environ.get('REPO_PATH', '')
today = os.environ.get('TODAY', '')
pid = os.getppid()

sensitive_patterns = [
    (r'sk-[a-zA-Z0-9_-]{20,}', '***API_KEY***'),
    (r'password[\"\']?\s*[:=]\s*[\"\']?[^\"\s]+', 'password: ***'),
    (r'api[_-]?key[\"\']?\s*[:=]\s*[\"\']?[^\"\s]+', 'api_key: ***'),
    (r'Bearer\s+[a-zA-Z0-9._-]+', 'Bearer ***'),
]

def mask_sensitive(text):
    for pattern, replacement in sensitive_patterns:
        text = re.sub(pattern, replacement, text, flags=re.IGNORECASE)
    return text

def extract_text(content):
    """content가 문자열이면 그대로, 리스트면 text 타입만 추출"""
    if isinstance(content, str):
        return content
    elif isinstance(content, list):
        texts = []
        for item in content:
            if isinstance(item, dict) and item.get('type') == 'text':
                texts.append(item.get('text', ''))
        return ' '.join(texts)
    return ''

prompts = []
try:
    with open(f'/tmp/claude_prompts_{pid}.jsonl', 'r') as f:
        for line in f:
            try:
                d = json.loads(line)
                if d.get('type') != 'user':
                    continue
                cwd = d.get('cwd') or ''
                if not repo_path or not cwd.startswith(repo_path):
                    continue
                ts = (d.get('timestamp') or '')[:10]
                if ts != today:
                    continue
                msg = d.get('message') or {}
                content = msg.get('content', '')
                text = extract_text(content)
                if len(text) > 50 and text.strip() not in ['응', 'ㅇㅇ', '확인', 'ok', 'yes', 'no']:
                    prompts.append(mask_sensitive(text))
            except json.JSONDecodeError:
                continue
            except Exception:
                continue
except FileNotFoundError:
    pass

for p in prompts[-30:]:
    print('---PROMPT---')
    print(p[:1000])
PYEOF

   # 임시 파일 삭제
   rm -f /tmp/claude_prompts_$$.jsonl
   ```

2. **인사이트 분석 기준**
   수집된 프롬프트를 다음 기준으로 평가:
   - **도구 조합**: MCP 서버 여러 개 사용, 파일 경로 참조
   - **구체성**: 명확한 목표와 컨텍스트 제공
   - **창의성**: 기존 자산 재활용, 새로운 접근법 제시
   - **사용자 중심**: UX/결과물에 대한 명확한 기대

3. **상위 3개 선별 후 인사이트 생성**
   ```markdown
   ## 🎯 프롬프트 인사이트

   ### 1. "[프롬프트 요약 제목]"

   **왜 이 프롬프트가 괜찮은지**
   - [구체적인 이유 1]
   - [구체적인 이유 2]
   - [구체적인 이유 3]

   **프롬프트 결과**
   - [간략한 결과 설명 1]
   - [간략한 결과 설명 2]
   ```

4. **프롬프트가 없는 경우**
   ```
   💡 오늘 프롬프트 인사이트: 수집된 프롬프트가 없습니다.
   ```

### 5단계: JSON 데이터 구성
다음 구조로 JSON 생성:
```json
{
  "date": "YYYY-MM-DD",
  "stats": {
    "commits": 5,
    "files": 12,
    "additions": 150,
    "deletions": 30
  },
  "commits": [
    {
      "sha": "abc123...",
      "time": "2025-01-15 14:30:00 +0900",
      "message": "feat: Add new feature",
      "author": "Developer",
      "files": ["src/index.ts", "src/utils.ts"],
      "additions": 50,
      "deletions": 10
    }
  ],
  "analysis": {
    "mainAreas": ["src", "tests", "docs"],
    "fileChanges": {"src/index.ts": 3, "README.md": 1}
  },
  "repository": {
    "path": "/path/to/repo",
    "remote": "git@github.com:user/repo.git"
  },
  "aiReport": "## 📊 일일 개발 리뷰\n\n...",
  "promptInsights": [
    {
      "prompt": "원본 프롬프트 (마스킹 처리됨)",
      "summary": "요약 제목",
      "whyGood": ["이유1", "이유2", "이유3"],
      "results": ["결과1", "결과2"]
    }
  ]
}
```

### 6단계: Own It API 전송
설정 파일 확인:
```bash
cat ~/.claude-daily-commands/config.json 2>/dev/null
```

**인증 모드** (API 키가 있는 경우):
```bash
curl -s -X POST "http://localhost:4000/api/daily-reviews/sync" \
  -H "Authorization: Bearer [API_KEY]" \
  -H "Content-Type: application/json" \
  -d '[JSON_DATA]'
```

**익명 모드** (API 키가 없는 경우):
```bash
curl -s -X POST "http://localhost:4000/api/anonymous-reviews" \
  -H "Content-Type: application/json" \
  -d '[JSON_DATA]'
```

### 7단계: 결과 표시

**성공 시:**
```
✅ Own It 동기화 완료!

📅 Daily Review - 2025-01-15
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 5개 커밋 | 12개 파일 | +150줄 -30줄
💡 주요 작업: src, tests

## Timeline
[14:30] feat: Add new feature (src)
[13:15] fix: Bug fix (tests)
...

## 📊 일일 개발 리뷰
[AI 생성 리포트]

## 🎯 프롬프트 인사이트

### 1. "MCP 서버 조합으로 문제 분석"

**왜 이 프롬프트가 괜찮은지**
- 멀티 도구 활용 요청
- 구체적인 문제 상황 제시
- 실제 환경 검증 요청

**프롬프트 결과**
- 문제 근본 원인 진단
- 대안 솔루션 구현

📊 리뷰 확인: http://localhost:3000/daily/[ID]
```

**익명 모드 성공 시:**
```
✅ 익명 리뷰 생성 완료!

🔗 웹에서 보기: http://localhost:3000/anonymous/[ID]
⚠️ 주의: 24시간 후 자동 삭제됩니다

💡 계정 등록하면 영구 저장됩니다: http://localhost:3000
```

**커밋이 없는 경우:**
```
📭 [날짜]에 커밋이 없습니다.
```

**API 연결 실패 시:**
```
⚠️ Own It 서버에 연결할 수 없습니다

로컬 결과만 표시합니다:
[타임라인 및 AI 리포트 출력]

💡 서버 실행: cd ~/own-it && pnpm dev
```

---

## 설정 파일 (선택사항)
`~/.claude-daily-commands/config.json`:
```json
{
  "ownit_api_key": "your-api-key",
  "ownit_api_url": "http://localhost:4000"
}
```

API 키 없이도 익명 모드로 사용 가능합니다.

---

## 주의사항
- 현재 디렉토리가 Git 저장소여야 합니다
- Own It 서버가 실행 중이어야 동기화됩니다
- 서버 없이도 로컬 분석 결과는 확인 가능합니다
