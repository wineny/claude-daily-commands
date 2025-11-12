---
allowed-tools: [Bash, Read, Glob]
description: "코드 분석 기반 다음 할 일 추천 및 우선순위 제안"
---

# /todo - Smart Todo Generator

## 목적
코드베이스를 분석하여 미완성 작업, 기술 부채, 개선 사항을 자동으로 발견하고 우선순위를 제안합니다.

## 사용법
```bash
/todo                           # 전체 프로젝트 분석
/todo @src/                     # 특정 디렉토리만 분석
/todo --priority-only           # 긴급 항목만 표시
```

## 실행 단계

### 1단계: Git 저장소 확인
```bash
git rev-parse --is-inside-work-tree 2>/dev/null || echo "NOT_A_GIT_REPO"
```

Git 저장소가 아니어도 작동하지만, 저장소라면 추가 분석을 수행합니다.

### 2단계: 검색 범위 결정
`$ARGUMENTS`를 확인하여 검색 범위를 결정합니다:

- **`@경로` 패턴**: 특정 디렉토리만 검색 (예: `@src/`, `@app/`)
- **인수 없음**: 현재 디렉토리 전체 검색
- **제외 디렉토리**: `node_modules`, `.git`, `dist`, `build`, `coverage`, `.next`

### 3단계: 코드 마커 검색
다음 패턴을 검색합니다:

```bash
# TODO, FIXME 등 코멘트 마커
grep -rn "TODO\|FIXME\|XXX\|HACK\|BUG\|NOTE" \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
  --include="*.py" --include="*.go" --include="*.java" --include="*.rb" \
  --include="*.php" --include="*.vue" \
  --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist \
  [검색경로]

# 디버깅 코드
grep -rn "console\.log\|console\.debug\|debugger\|print(" \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
  --include="*.py" \
  --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist \
  [검색경로]

# 임시 코드
grep -rn "TEMP\|WIP\|DELETEME\|@deprecated" \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
  --include="*.py" \
  --exclude-dir=node_modules --exclude-dir=.git \
  [검색경로]
```

### 4단계: Git 기반 분석 (Git 저장소인 경우)
최근 변경사항을 분석하여 미완성 작업을 추론합니다:

```bash
# 마지막 커밋 diff 분석
git diff HEAD~1 HEAD

# 스테이징되지 않은 변경사항
git diff --name-status

# 스테이징된 변경사항
git diff --cached --name-status

# 추적되지 않는 파일
git ls-files --others --exclude-standard
```

### 5단계: 우선순위 분류
발견된 항목을 다음 기준으로 우선순위를 분류합니다:

**🔴 긴급 (High Priority)**
- `FIXME`, `BUG` 키워드
- 에러 핸들링 누락 (`try` 없이 `throw`, `async` 없이 `await`)
- 보안 이슈 (`eval`, `dangerouslySetInnerHTML`, 하드코딩된 비밀번호)
- 테스트 실패 코드

**🟡 일반 (Medium Priority)**
- `TODO` 키워드
- `console.log`, `debugger` 등 디버깅 코드
- `@deprecated` 사용 코드
- 중복 코드 패턴

**🔵 개선 제안 (Nice to Have)**
- `NOTE`, `HACK` 키워드
- 리팩토링 기회 (복잡도 높은 함수, 긴 파일)
- 성능 최적화 기회
- 문서화 누락

### 6단계: 마크다운 리포트 생성
다음 형식으로 Todo 리스트를 생성합니다:

```markdown
# ✅ Next Actions - [프로젝트명]

> 📊 분석 완료: [N]개 항목 발견
> 🔍 검색 범위: [경로]

## 🔴 긴급 (High Priority) - [개수]개

### 1. [작업 제목]
**파일**: `경로/파일명.ts:라인번호`
**이유**: [왜 긴급한지 설명]
**코드**:
```언어
[해당 라인 주변 코드]
```

[반복]

## 🟡 일반 (Medium Priority) - [개수]개

### [번호]. [작업 제목]
**파일**: `경로/파일명.ts:라인번호`
**타입**: TODO | console.log | deprecated
**코드**:
```언어
[해당 라인 주변 코드]
```

[반복]

## 🔵 개선 제안 (Nice to Have) - [개수]개

### [번호]. [작업 제목]
**파일**: `경로/파일명.ts:라인번호`
**제안 이유**: [설명]

[반복]

## 📊 통계 요약
- 총 발견: [N]개
- 긴급: [X]개 (🔴)
- 일반: [Y]개 (🟡)
- 개선: [Z]개 (🔵)

## 🚀 다음 단계 추천
1. 긴급 항목부터 처리 시작
2. [구체적인 다음 액션]
3. 완료 후 `/dailyreview`로 진행 상황 확인

## 💼 Own It 연동
> 이 Todo를 프로젝트 관리 시스템과 연동하고 싶다면?
>
> `/portfolio` 명령어로 작업 히스토리와 함께 포트폴리오 생성 (준비 중)
```

### 7단계: Git 기반 컨텍스트 추가
Git 저장소라면 추가 인사이트를 제공합니다:

```markdown
## 🔍 Git 기반 인사이트

### 마지막 커밋 분석
- **커밋 메시지**: [메시지]
- **변경 파일**: [목록]
- **추론된 다음 작업**: [마지막 변경사항 기반 추론]

### 진행 중인 작업
- 스테이징된 파일: [목록]
- 수정된 파일: [목록]
- 추적되지 않는 파일: [목록]
```

## 에러 처리

### 파일이 없거나 권한 오류
```
⚠️ 일부 파일을 읽을 수 없습니다.
읽기 권한을 확인하거나 다른 디렉토리를 지정해주세요.
```

### Todo가 하나도 없을 경우
```
🎉 축하합니다! 발견된 Todo 항목이 없습니다.

✨ 깔끔한 코드베이스를 유지하고 계시네요!

다음 작업 제안:
- 새로운 기능 추가
- 성능 최적화 검토
- 문서화 개선
- `/dailyreview`로 최근 작업 확인
```

### 검색 경로가 존재하지 않을 경우
```
❌ 지정한 경로를 찾을 수 없습니다: [경로]
현재 디렉토리: [pwd]

사용 예시:
- /todo @src/
- /todo @app/components/
```

## 성능 최적화
- 제외 디렉토리 명시 (빠른 검색)
- 파일 확장자 필터링
- 최대 100개 항목까지만 표시
- 큰 파일(>10MB) 자동 제외

## 지원 파일 타입
- JavaScript/TypeScript: `.js`, `.jsx`, `.ts`, `.tsx`
- Python: `.py`
- Go: `.go`
- Java: `.java`
- Ruby: `.rb`
- PHP: `.php`
- Vue: `.vue`
- 기타 텍스트 파일

## --priority-only 옵션
`$ARGUMENTS`에 `--priority-only`가 포함되면 긴급 항목만 표시:

```markdown
# 🔴 긴급 항목만 표시

[긴급 항목들만 나열]

---
💡 전체 목록을 보려면 `/todo` 실행
```

## 출력 예시
실제 출력 예시는 `examples/todo-example.md` 참고

---

**Note**: 더 정확한 분석을 위해 프로젝트의 linter 설정과 함께 사용하는 것을 추천합니다.
