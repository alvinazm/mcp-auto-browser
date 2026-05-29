# 抖音视频上传 - HTTP 模式

## 背景问题

在 `stdio` 模式下，每次 MCP 调用启动独立进程，但 Chrome 扩展的 HTTP 服务器返回错误：

```
Already connected to a transport. Call close() before connecting to a new transport
```

这是因为 Chrome MCP 服务器端限制了单连接只能发送一个请求。

## 解决方案

使用 **HTTP 模式**（Streamable HTTP），通过 `MCP-Session-ID` 头维持会话。

### 工作原理

1. stdio 服务器启动后监听 `http://127.0.0.1:12306/mcp`
2. 初始化请求（`initialize`）时，服务器在响应头返回 `Mcp-Session-Id`
3. 后续请求通过 `MCP-Session-ID` 头使用同一会话

## 脚本示例

```bash
#!/bin/bash

PORT=12306
BASE_URL="http://127.0.0.1:$PORT/mcp"
SESSION_FILE="/tmp/mcp_session_$$"

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

# 启动 stdio 服务器
node "$STDIO_SERVER" &
SERVER_PID=$!
sleep 3

# 初始化
INIT_RESP=$(mcp_http_init '{"jsonrpc":"2.0","method":"initialize","params":{...},"id":1}')

# 工具调用
mcp_http_call '{"jsonrpc":"2.0","method":"tools/call","params":{...},"id":2}'

# 清理
kill $SERVER_PID 2>/dev/null
rm -f "$SESSION_FILE"
```

## 关键点

1. **响应头提取**：`Mcp-Session-Id` 头区分大小写，不是 `MCP-Session-ID`
2. **body 提取**：HTTP 响应中 header 和 body 之间有空行，使用 `sed '1,/^\r*$/d'` 分离
3. **session 持久化**：保存到文件供后续调用使用
4. **启动延迟**：stdio 服务器启动后需等待约 3 秒再发送请求

## 对比 stdio 模式

| 特性 | stdio 模式 | HTTP 模式 |
|------|-----------|-----------|
| 连接方式 | 每次请求启动新进程 | 单一连接，会话复用 |
| 多请求支持 | ❌ 会话冲突 | ✅ 正常工作 |
| 实现复杂度 | 简单 | 稍复杂 |
| 性能 | 每次创建进程开销 | 连接复用，更高效 |

## 文件路径

- stdio 服务器：`/Users/azm/Library/pnpm/global/5/node_modules/mcp-chrome-bridge/dist/mcp/mcp-server-stdio.js`
- 配置文件：`/Users/azm/Library/pnpm/global/5/node_modules/mcp-chrome-bridge/dist/mcp/stdio-config.json`
- 测试脚本：`./test_http.sh`
