---
allowed-tools: [Bash, Grep, Glob, Task]
description: "코드 Todo 간결 분석 (v2 최적화 버전)"
---

# /todov2 - Smart Todo (Optimized)

당신은 코드베이스에서 **Todo를 빠르고 간결하게** 찾는 전문가입니다.

## 핵심 원칙
- **효율성**: 병렬 검색으로 빠른 실행
- **간결성**: 핵심만 표시 (기본 15줄 이내)
- **실용성**: 즉시 실행 가능한 액션 중심

## 사용법
```bash
/todov2                    # 간결한 todo 리스트 (기본)
/todov2 --brief            # 통계만 표시 (3줄)
/todov2 --full             # v1 수준 상세 정보
/todov2 --priority-only    # 긴급 항목만
/todov2 @src/              # 특정 디렉토리만
```

## 실행 단계

### 1. 검색 범위 결정
```bash
# 기본: 현재 디렉토리 전체
# @경로: 특정 디렉토리만 (예: @src/, @app/)
# 항상 제외: node_modules, .git, dist, build, coverage
```

### 2. 통합 검색 (병렬 실행 권장)
**중요**: 가능하면 Task 에이전트에게 위임하여 병렬 검색

```bash
# 3가지 패턴을 병렬로 검색
Pattern 1: TODO, FIXME, XXX, HACK, BUG, NOTE
Pattern 2: console.log, debugger, print(
Pattern 3: TEMP, WIP, DELETEME, @deprecated
```

**Grep 명령어**:
```bash
# 코드 마커
grep -rn "TODO\|FIXME\|XXX\|HACK\|BUG" \
  --include="*.{ts,tsx,js,jsx,py,go,java}" \
  --exclude-dir={node_modules,.git,dist} .

# 디버깅 코드
grep -rn "console\.\(log\|debug\)\|debugger" \
  --include="*.{ts,tsx,js,jsx}" \
  --exclude-dir={node_modules,.git,dist} .

# 임시 코드
grep -rn "TEMP\|WIP\|@deprecated" \
  --include="*.{ts,tsx,js,jsx}" \
  --exclude-dir={node_modules,.git} .
```

### 3. 우선순위 자동 분류
- 🔴 **긴급**: FIXME, BUG, 보안 이슈
- 🟡 **일반**: TODO, console.log, @deprecated
- 🔵 **개선**: NOTE, HACK, 리팩토링 기회

### 4. 출력 모드 선택

#### A) 기본 모드 (플래그 없음)
```markdown
# ✅ Todo ([N]개 발견)

## 🔴 긴급 ([X])
1. [파일:라인] - [키워드]: [간단한 설명]
2. [파일:라인] - [키워드]: [간단한 설명]

## 🟡 일반 ([Y])
3. [파일:라인] - [타입]
4. [파일:라인] - [타입]

## 🔵 개선 ([Z])
5. [파일:라인] - [제안]
```

**예시**:
```markdown
# ✅ Todo (6개 발견)

## 🔴 긴급 (2)
1. src/auth/login.ts:3 - FIXME: 인증 로직 구현
2. src/auth/login.ts:1 - TODO: 에러 핸들링

## 🟡 일반 (2)
3. src/auth/login.ts:4 - console.log 제거
4. tests/auth.test.ts:4 - 테스트 케이스 추가

## 🔵 개선 (2)
5. tests/auth.test.ts:10 - 실패 케이스 테스트
6. src/auth/login.ts:14 - 임시 구현 개선
```

#### B) --brief 모드
```markdown
✅ [N] todos | 🔴 [X]긴급 🟡 [Y]일반 🔵 [Z]개선
다음: [가장 긴급한 항목 1개]
```

**예시**:
```markdown
✅ 6 todos | 🔴 2긴급 🟡 2일반 🔵 2개선
다음: src/auth/login.ts - 인증 로직 구현
```

#### C) --full 모드
v1과 동일한 상세 출력:
- 각 항목마다 코드 블록 포함
- 상세한 이유 및 제안
- Git 기반 인사이트
- 통계 요약
- Own It 연동 안내

#### D) --priority-only 모드
```markdown
# 🔴 긴급 항목만 ([X]개)

1. [파일:라인] - [설명]
2. [파일:라인] - [설명]

💡 전체 목록: /todov2
```

### 5. Git 컨텍스트 추가 (선택적)
Git 저장소인 경우, 마지막에 간단히 추가:
```markdown
📌 최근 변경: [마지막 커밋 메시지]
```

### 6. 에러 처리

**Todo가 없는 경우**:
```
🎉 No todos found!

코드베이스가 깔끔하네요!
```

**검색 경로 없음**:
```
❌ Path not found: [경로]

Try: /todov2 @src/
```

## 구현 가이드

### 성능 최적화 전략

1. **Task 에이전트 활용 (복잡한 경우)**
```markdown
파일 수 >50 또는 디렉토리 >10:
→ Task 에이전트에게 검색 위임
→ 병렬 처리로 속도 향상

단순한 경우:
→ 직접 Grep 3회 실행
```

2. **검색 범위 최소화**
```bash
# 파일 확장자 필터링
--include="*.{ts,tsx,js,jsx,py}"

# 디렉토리 제외
--exclude-dir={node_modules,.git,dist,build,coverage,.next}

# 최대 결과 제한
| head -100
```

3. **중복 제거**
```bash
# 같은 파일의 여러 todo는 그룹화
# 예: src/auth/login.ts (3개 todo) → 한 번에 표시
```

### Git 명령 통합 (선택적)
```bash
# Git 저장소면 마지막 커밋 정보만 추가
if git rev-parse --git-dir >/dev/null 2>&1; then
  LAST_COMMIT=$(git log -1 --pretty=format:"%s" 2>/dev/null)
  echo "📌 최근 변경: $LAST_COMMIT"
fi
```

### 우선순위 판별 로직
```python
# 의사코드
if keyword in ["FIXME", "BUG"] or "security" in context:
    priority = "🔴 긴급"
elif keyword in ["TODO", "console.log", "@deprecated"]:
    priority = "🟡 일반"
else:
    priority = "🔵 개선"
```

## 성능 목표
- ✅ Accept 요청: 3-5회 (v1: 10-14회)
- ✅ 실행 시간: <10초 (v1: ~20초)
- ✅ 기본 출력: <20줄 (v1: ~70줄)

## 주의사항
- 기본 모드는 파일:라인만 (코드 블록 생략)
- --full 모드만 코드 블록 포함
- 최대 100개 항목까지만 표시
- 큰 파일(>10MB) 자동 제외

---

**v2 개선점**: 70% 짧은 출력, Task 에이전트 활용, 빠른 검색
