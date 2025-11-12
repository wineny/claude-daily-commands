---
allowed-tools: [Bash]
description: "Configure Own It integration for daily reviews"
---

# /dailyreview-setup - Own It Integration Setup

Own It 백엔드와 연동하기 위한 API 키를 설정합니다.

## 실행 과정

### 1. 설정 디렉토리 생성
```bash
CONFIG_DIR="$HOME/.claude-daily-commands"
CONFIG_FILE="$CONFIG_DIR/config.json"

# 디렉토리 생성 (없으면)
if [ ! -d "$CONFIG_DIR" ]; then
  mkdir -p "$CONFIG_DIR"
  echo "✅ Created config directory: $CONFIG_DIR"
fi
```

### 2. 기존 설정 확인
```bash
if [ -f "$CONFIG_FILE" ]; then
  echo "⚠️  Configuration already exists"
  echo ""
  cat "$CONFIG_FILE" | jq '.'
  echo ""
  read -p "Do you want to overwrite? (y/N): " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
  fi
fi
```

### 3. API 키 입력 받기
```bash
echo "🔑 Own It API Key Setup"
echo ""
echo "To get your API key:"
echo "1. Go to Own It dashboard: http://localhost:3000"
echo "2. Navigate to Settings → API Keys"
echo "3. Click 'Generate New API Key'"
echo "4. Copy the key (starts with 'own_it_sk_')"
echo ""

read -p "Enter your API key: " API_KEY

# API 키 형식 검증
if [[ ! $API_KEY =~ ^own_it_sk_ ]]; then
  echo "❌ Invalid API key format"
  echo "💡 API key should start with 'own_it_sk_'"
  exit 1
fi
```

### 4. API URL 입력 받기
```bash
echo ""
read -p "Enter API URL (default: http://localhost:3001): " API_URL

# 기본값 설정
if [ -z "$API_URL" ]; then
  API_URL="http://localhost:3001"
fi

# URL 형식 검증
if [[ ! $API_URL =~ ^https?:// ]]; then
  echo "❌ Invalid URL format"
  echo "💡 URL should start with http:// or https://"
  exit 1
fi
```

### 5. 설정 저장
```bash
# JSON 생성
cat > "$CONFIG_FILE" << EOF
{
  "ownit": {
    "apiKey": "$API_KEY",
    "apiUrl": "$API_URL"
  }
}
EOF

# 파일 권한 설정 (읽기/쓰기 본인만)
chmod 600 "$CONFIG_FILE"

echo ""
echo "✅ Configuration saved successfully"
echo ""
```

### 6. 연결 테스트
```bash
echo "🧪 Testing connection..."
echo ""

# API 엔드포인트 테스트
RESPONSE=$(curl -s -X GET "$API_URL/api/daily-reviews" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json")

# 응답 확인
if echo "$RESPONSE" | jq -e '.success' &>/dev/null; then
  echo "✅ Connection successful!"
  echo ""
  echo "🎉 You're all set! Now you can use:"
  echo "   /dailyreviewv2-sync       # Sync today's work"
  echo "   /dailyreviewv2-sync week  # Sync last 7 days"
  echo ""
elif echo "$RESPONSE" | jq -e '.message' &>/dev/null; then
  ERROR_MSG=$(echo "$RESPONSE" | jq -r '.message')
  echo "❌ Connection failed: $ERROR_MSG"
  echo ""
  echo "💡 Please check:"
  echo "   - Is the Own It server running?"
  echo "   - Is the API key correct?"
  echo "   - Is the API URL correct?"
  echo ""
  read -p "Do you want to keep this configuration anyway? (y/N): " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    rm "$CONFIG_FILE"
    echo "Configuration removed"
    exit 1
  fi
else
  echo "⚠️  Could not connect to server"
  echo ""
  echo "Response: $RESPONSE"
  echo ""
  echo "💡 Configuration saved, but connection test failed"
  echo "   You can still try syncing with /dailyreviewv2-sync"
fi
```

### 7. 설정 정보 표시
```bash
echo ""
echo "📁 Configuration location:"
echo "   $CONFIG_FILE"
echo ""
echo "🔧 To update configuration:"
echo "   /dailyreview-setup"
echo ""
echo "🗑️  To remove configuration:"
echo "   rm $CONFIG_FILE"
```

## 설정 파일 구조

`~/.claude-daily-commands/config.json`:
```json
{
  "ownit": {
    "apiKey": "own_it_sk_xxxxxxxxxxxxxxxxxxxxxxxx",
    "apiUrl": "http://localhost:3001"
  }
}
```

## 보안 고려사항

- 설정 파일은 `chmod 600`으로 본인만 읽기/쓰기 가능
- API 키는 절대 Git에 커밋하지 않기
- `.gitignore`에 `~/.claude-daily-commands/` 추가 권장
- 프로덕션 환경에서는 HTTPS 사용 필수

## 에러 케이스

**잘못된 API 키 형식**:
```
❌ Invalid API key format
💡 API key should start with 'own_it_sk_'
```

**잘못된 URL 형식**:
```
❌ Invalid URL format
💡 URL should start with http:// or https://
```

**연결 실패**:
```
❌ Connection failed: Unauthorized

💡 Please check:
   - Is the Own It server running?
   - Is the API key correct?
   - Is the API URL correct?

Do you want to keep this configuration anyway? (y/N):
```

## 사용 예시

```bash
# 초기 설정
$ /dailyreview-setup
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

🎉 You're all set! Now you can use:
   /dailyreviewv2-sync       # Sync today's work
   /dailyreviewv2-sync week  # Sync last 7 days
```

---

**Quick Setup**: 대화형 설정 → 자동 연결 테스트 → 즉시 사용 가능
