---
allowed-tools: [Bash]
description: "Own It에 오늘의 Git 커밋 자동 동기화"
---

# /dailyreview-sync - Own It Auto Sync

## 목적
현재 프로젝트의 오늘 Git 커밋을 Own It 백엔드에 자동으로 동기화합니다.

## 사용법
```bash
/dailyreview-sync              # 오늘 작업 동기화
/dailyreview-sync yesterday    # 어제 작업 동기화
/dailyreview-sync week         # 최근 7일 작업 동기화
```

## 실행 단계

### 1단계: 현재 디렉토리 확인
사용자에게 현재 작업 디렉토리를 알립니다:
```
🔄 Own It 동기화 시작...
📂 현재 디렉토리: [pwd 결과]
```

### 2단계: Git 저장소 확인
Bash 도구를 사용하여 Git 저장소인지 확인:
```bash
git rev-parse --is-inside-work-tree 2>/dev/null
```

Git 저장소가 아니면:
```
❌ Git 저장소가 아닙니다
💡 Git 프로젝트 디렉토리로 이동 후 다시 시도해주세요.
```

### 3단계: 스크립트 경로 확인
다음 경로들을 순서대로 확인:
1. `$HOME/development/claude-daily-commands/scripts/sync-daily-review.sh`
2. `$HOME/claude-daily-commands/scripts/sync-daily-review.sh`

둘 다 없으면:
```
❌ sync-daily-review.sh 스크립트를 찾을 수 없습니다

설치 방법:
1. cd ~
2. git clone https://github.com/wineny/claude-daily-commands.git

API 키 설정:
cd ~/claude-daily-commands
./scripts/setup-ownit.sh
```

### 4단계: 동기화 실행
**CRITICAL**: 반드시 Bash 도구를 사용하여 다음 명령어를 **실제로 실행**해야 합니다:

시간 범위에 따라:
- `$ARGUMENTS`가 비어있거나 "today": `bash [SCRIPT_PATH]`
- `$ARGUMENTS`에 "yesterday" 포함: `bash [SCRIPT_PATH] yesterday`
- `$ARGUMENTS`에 "week" 포함: `bash [SCRIPT_PATH] week`

실행 전 메시지:
```
🔄 Own It에 동기화 중...
```

### 5단계: 결과 확인
스크립트 실행 결과를 사용자에게 표시합니다.

성공 시:
```
✅ Own It 동기화 완료!
📊 대시보드: http://localhost:4000/dashboard
```

실패 시:
```
⚠️ 동기화 실패

확인사항:
1. API 키 설정: cd ~/development/claude-daily-commands && ./scripts/setup-ownit.sh
2. Own It 서버 실행 여부: http://localhost:4000
3. 네트워크 연결 상태

문제가 계속되면 다음 명령으로 직접 확인:
bash ~/development/claude-daily-commands/scripts/sync-daily-review.sh
```

## 주의사항
- Own It API 서버가 실행 중이어야 합니다 (포트 4000)
- API 키가 설정되어 있어야 합니다 (`~/.claude-daily-commands/config.json`)
- 현재 디렉토리가 Git 저장소여야 합니다

## 에러 처리

### 설정 파일 없음
```
⚠️ API 키가 설정되지 않았습니다

설정 방법:
cd ~/development/claude-daily-commands
./scripts/setup-ownit.sh

이후 다시 시도:
/dailyreview-sync
```

### 서버 연결 실패
```
⚠️ Own It 서버에 연결할 수 없습니다

확인사항:
1. 서버 실행: cd ~/development/own-it/apps/api && pnpm dev
2. 포트 확인: http://localhost:4000/health
```

---

**Note**: 이 명령어는 sync-daily-review.sh 스크립트에 의존합니다.
