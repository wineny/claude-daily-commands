#!/bin/bash
# setup-ownit.sh - Configure Own It integration

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONFIG_DIR="$HOME/.claude-daily-commands"
CONFIG_FILE="$CONFIG_DIR/config.json"

echo ""
echo -e "${BLUE}🔑 Own It API Key Setup${NC}"
echo ""

# Create config directory
if [ ! -d "$CONFIG_DIR" ]; then
  mkdir -p "$CONFIG_DIR"
  chmod 700 "$CONFIG_DIR"
  echo -e "${GREEN}✅ Created config directory: $CONFIG_DIR${NC}"
  echo ""
fi

# Check existing configuration
if [ -f "$CONFIG_FILE" ]; then
  echo -e "${YELLOW}⚠️  Configuration already exists${NC}"
  echo ""

  if command -v jq &>/dev/null; then
    cat "$CONFIG_FILE" | jq '.' 2>/dev/null || cat "$CONFIG_FILE"
  else
    cat "$CONFIG_FILE"
  fi

  echo ""
  read -p "Do you want to overwrite? (y/N): " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
  fi
  echo ""
fi

# Instructions
echo "To get your API key:"
echo "1. Go to Own It dashboard: http://localhost:3000"
echo "2. Navigate to Settings → API Keys"
echo "3. Click 'Generate New API Key'"
echo "4. Copy the key (starts with 'own_it_sk_')"
echo ""

# Get API key
read -p "Enter your API key: " API_KEY

# Validate API key format
if [[ ! $API_KEY =~ ^own_it_sk_ ]]; then
  echo -e "${RED}❌ Invalid API key format${NC}"
  echo "💡 API key should start with 'own_it_sk_'"
  exit 1
fi

# Get API URL
echo ""
read -p "Enter API URL (default: http://localhost:3001): " API_URL

# Set default
if [ -z "$API_URL" ]; then
  API_URL="http://localhost:3001"
fi

# Validate URL format
if [[ ! $API_URL =~ ^https?:// ]]; then
  echo -e "${RED}❌ Invalid URL format${NC}"
  echo "💡 URL should start with http:// or https://"
  exit 1
fi

# Create config file
if command -v jq &>/dev/null; then
  # Use jq for proper JSON formatting
  jq -n \
    --arg key "$API_KEY" \
    --arg url "$API_URL" \
    '{ownit: {apiKey: $key, apiUrl: $url}}' > "$CONFIG_FILE"
else
  # Fallback to manual JSON creation
  cat > "$CONFIG_FILE" << EOF
{
  "ownit": {
    "apiKey": "$API_KEY",
    "apiUrl": "$API_URL"
  }
}
EOF
fi

# Set file permissions (owner read/write only)
chmod 600 "$CONFIG_FILE"

echo ""
echo -e "${GREEN}✅ Configuration saved successfully${NC}"
echo ""

# Test connection
echo "🧪 Testing connection..."
echo ""

if command -v curl &>/dev/null; then
  RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$API_URL/api/daily-reviews" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" 2>/dev/null)

  HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
  BODY=$(echo "$RESPONSE" | sed '$d')

  if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "401" ]; then
    # 401 is expected if there are no reviews yet
    if echo "$BODY" | python3 -c "import sys, json; json.load(sys.stdin)" 2>/dev/null; then
      echo -e "${GREEN}✅ Connection successful!${NC}"
      echo ""
      echo "🎉 You're all set! Now you can use:"
      echo "   ./scripts/sync-daily-review.sh       # Sync today's work"
      echo "   ./scripts/sync-daily-review.sh week  # Sync last 7 days"
      echo ""
    else
      echo -e "${YELLOW}⚠️  Unexpected response format${NC}"
      echo ""
      echo "Response: $BODY"
      echo ""
      echo "💡 Configuration saved, you can still try syncing"
    fi
  else
    echo -e "${RED}❌ Connection failed (HTTP $HTTP_CODE)${NC}"
    echo ""
    if [ -n "$BODY" ]; then
      if command -v jq &>/dev/null && echo "$BODY" | jq . &>/dev/null; then
        ERROR_MSG=$(echo "$BODY" | jq -r '.message // "Unknown error"')
        echo "Error: $ERROR_MSG"
      else
        echo "Response: $BODY"
      fi
    fi
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
  fi
else
  echo -e "${YELLOW}⚠️  curl not installed, skipping connection test${NC}"
  echo "💡 Install curl to test the connection"
  echo ""
fi

# Show configuration info
echo ""
echo "📁 Configuration location:"
echo "   $CONFIG_FILE"
echo ""
echo "🔧 To update configuration:"
echo "   ./scripts/setup-ownit.sh"
echo ""
echo "🗑️  To remove configuration:"
echo "   rm $CONFIG_FILE"
echo ""
