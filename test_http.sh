#!/bin/bash

# 抖音上传脚本 - HTTP 模式

PORT=12306
BASE_URL="http://127.0.0.1:$PORT/mcp"
SESSION_FILE="/tmp/mcp_session_$$"
STDIO_SERVER="${STDIO_SERVER:-/Users/azm/Library/pnpm/global/5/node_modules/mcp-chrome-bridge/dist/mcp/mcp-server-stdio.js}"

mcp_http_init() {
    local JSON="$1"
    local RESP=$(curl -s -i "$BASE_URL" \
        -X POST \
        -H "Content-Type: application/json" \
        -H "Accept: application/json, text/event-stream" \
        -d "$JSON" 2>&1)

    local BODY=$(echo "$RESP" | sed '1,/^\r*$/d')
    local NEW_SID=$(echo "$RESP" | grep -i "Mcp-Session-Id:" | cut -d' ' -f2 | tr -d '\r' | head -1)
    [ -n "$NEW_SID" ] && echo "$NEW_SID" > "$SESSION_FILE"
    echo "$BODY"
}

mcp_http_call() {
    local JSON="$1"
    local SID=$(cat "$SESSION_FILE" 2>/dev/null)

    local RESP=$(curl -s -i "$BASE_URL" \
        -X POST \
        -H "Content-Type: application/json" \
        -H "Accept: application/json, text/event-stream" \
        -H "MCP-Session-ID: $SID" \
        -d "$JSON" 2>&1)

    local NEW_SID=$(echo "$RESP" | grep -i "Mcp-Session-Id:" | cut -d' ' -f2 | tr -d '\r' | head -1)
    [ -n "$NEW_SID" ] && echo "$NEW_SID" > "$SESSION_FILE"

    echo "$RESP" | sed '1,/^\r*$/d'
}

VIDEO_PATH="${1:-/Users/azm/Downloads/榴莲小人.mp4}"

echo "============================================"
echo "抖音上传 - HTTP 模式"
echo "视频: $VIDEO_PATH"
echo "============================================"

# 确保端口干净
kill $(lsof -i :$PORT -t) 2>/dev/null
sleep 1

# 启动 stdio 服务器
node "$STDIO_SERVER" &
SERVER_PID=$!
sleep 3

# 初始化
echo ""
echo "=== 初始化 ==="
INIT_RESP=$(mcp_http_init '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"cli","version":"1.0"}},"id":1}')
echo "$INIT_RESP"

# 打开上传页面
echo ""
echo "=== 打开上传页面 ==="
NAV_RESP=$(mcp_http_call '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_navigate","arguments":{"url":"https://creator.douyin.com/creator-micro/content/upload?enter_from=dou_web"}},"id":2}')
echo "$NAV_RESP"

sleep 3

# 点击上传按钮
echo ""
echo "=== 点击上传按钮 ==="
CLICK_RESP=$(mcp_http_call '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_click_element","arguments":{"selector":"button.semi-button","selectorType":"css"}},"id":3}')
echo "$CLICK_RESP"

sleep 2

# 上传视频
echo ""
echo "=== 上传视频 ==="
ESCAPED_PATH=$(echo "$VIDEO_PATH" | sed 's/"/\\"/g')
UPLOAD_RESP=$(mcp_http_call "{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_upload_file\",\"arguments\":{\"selector\":\"input[type=\\\"file\\\"]\",\"filePath\":\"$ESCAPED_PATH\"}},\"id\":4}")
echo "$UPLOAD_RESP"

# 清理
kill $SERVER_PID 2>/dev/null
rm -f "$SESSION_FILE"

echo ""
echo "============================================"
echo "完成!"
echo "============================================"