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
  "aiReport": "## 📊 일일 개발 리뷰\n\n..."
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
