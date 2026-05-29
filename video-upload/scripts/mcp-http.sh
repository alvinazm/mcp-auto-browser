#!/bin/bash

# MCP HTTP 模式公共函数库
# 供各平台上传脚本使用

PORT=12306
BASE_URL="http://127.0.0.1:$PORT/mcp"
SESSION_FILE="/tmp/mcp_session_$$"

# 等待 MCP 服务就绪
mcp_wait_ready() {
    local max_attempts=10
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        # 尝试初始化
        RESP=$(curl -s -i "$BASE_URL" -X POST \
            -H "Content-Type: application/json" \
            -H "Accept: application/json, text/event-stream" \
            -d '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"cli","version":"1.0"}},"id":1}' 2>&1)

        if echo "$RESP" | grep -q '"jsonrpc"'; then
            echo "$RESP" | sed '1,/^\r*$/d'
            grep -i "Mcp-Session-Id:" <<< "$RESP" | cut -d' ' -f2 | tr -d '\r' > "$SESSION_FILE"
            return 0
        fi

        echo "等待 MCP 服务就绪... ($attempt/$max_attempts)"
        sleep 1
        attempt=$((attempt + 1))
    done

    echo "MCP 服务启动失败"
    return 1
}

# 初始化 MCP 连接
mcp_init() {
    local RESP=$(curl -s -i "$BASE_URL" -X POST \
        -H "Content-Type: application/json" \
        -H "Accept: application/json, text/event-stream" \
        -d "$1" 2>&1)

    echo "$RESP" | sed '1,/^\r*$/d'
    grep -i "Mcp-Session-Id:" <<< "$RESP" | cut -d' ' -f2 | tr -d '\r' > "$SESSION_FILE"
}

# MCP 调用
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

# 清理 session 文件
mcp_cleanup() {
    rm -f "$SESSION_FILE"
}