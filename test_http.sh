#!/bin/bash

# 抖音上传脚本 - HTTP 模式
# 直接连接 Chrome 扩展 HTTP 服务

PORT=12306
BASE_URL="http://127.0.0.1:$PORT/mcp"
SESSION_FILE="/tmp/mcp_session_$$"

mcp_init() {
    local RESP=$(curl -s -i "$BASE_URL" -X POST \
        -H "Content-Type: application/json" \
        -H "Accept: application/json, text/event-stream" \
        -d "$1" 2>&1)

    echo "$RESP" | sed '1,/^\r*$/d'
    grep -i "Mcp-Session-Id:" <<< "$RESP" | cut -d' ' -f2 | tr -d '\r' > "$SESSION_FILE"
}

mcp_call() {
    local SID=$(cat "$SESSION_FILE" 2>/dev/null)
    local RESP=$(curl -s -i "$BASE_URL" -X POST \
        -H "Content-Type: application/json" \
        -H "Accept: application/json, text/event-stream" \
        -H "MCP-Session-ID: $SID" \
        -d "$1" 2>&1)

    grep -i "Mcp-Session-Id:" <<< "$RESP" | cut -d' ' -f2 | tr -d '\r' > "$SESSION_FILE"
    echo "$RESP" | sed '1,/^\r*$/d'
}

VIDEO_PATH="${1:-/Users/azm/Downloads/榴莲小人.mp4}"

echo "============================================"
echo "抖音上传 - HTTP 模式"
echo "视频: $VIDEO_PATH"
echo "============================================"

sleep 1

echo ""
echo "=== 初始化 ==="
mcp_init '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"cli","version":"1.0"}},"id":1}'

echo ""
echo "=== 打开上传页面 ==="
mcp_call '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_navigate","arguments":{"url":"https://creator.douyin.com/creator-micro/content/upload?enter_from=dou_web"}},"id":2}'

sleep 3

echo ""
echo "=== 点击上传按钮 ==="
mcp_call '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_click_element","arguments":{"selector":"button.semi-button","selectorType":"css"}},"id":3}'

sleep 2

echo ""
echo "=== 上传视频 ==="
ESCAPED_PATH=$(echo "$VIDEO_PATH" | sed 's/"/\\"/g')
mcp_call "{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_upload_file\",\"arguments\":{\"selector\":\"input[type=\\\"file\\\"]\",\"filePath\":\"$ESCAPED_PATH\"}},\"id\":4}"

rm -f "$SESSION_FILE"
echo ""
echo "完成!"