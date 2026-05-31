#!/bin/bash

# 微信视频上传脚本 (HTTP 模式)
# 只打开上传页面，不进行其他操作

PLATFORM_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PLATFORM_SCRIPT_DIR/../human.sh"

# 清理旧进程，确保每个平台使用新连接
lsof -i :12306 2>/dev/null | grep -v PID | awk '{print $2}' | head -1 | xargs kill -9 2>/dev/null
rm -f /tmp/mcp_session_*
sleep 3

# 加载 MCP HTTP 函数
source "$PLATFORM_SCRIPT_DIR/../mcp-http.sh"

# 检测是否被 source（作为函数被调用）
_is_sourced() {
    [[ "${BASH_SOURCE[0]}" != "${0}" ]]
}

upload_video_weixin() {
    echo "============================================"
    echo "微信视频上传脚本 (HTTP模式)"
    echo "============================================"

    echo ""
    echo "=== 初始化 MCP ==="
    mcp_wait_ready || { echo "MCP 初始化失败"; return 1; }

    echo ""
    echo "=== 打开上传页面 ==="
    # 微信视频上传页面 URL
    NAVIGATE_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_navigate","arguments":{"url":"https://channels.weixin.qq.com/platform/post/create"}},"id":2}'
    RESULT=$(mcp_call "$NAVIGATE_JSON")

    if ! echo "$RESULT" | grep -q '"isError":false'; then
        echo "导航失败"
        return 1
    fi
    echo "导航: OK"

    echo ""
    echo "============================================"
    echo "页面已打开: https://channels.weixin.qq.com/platform/post/create"
    echo "============================================"
}

if ! _is_sourced; then
    upload_video_weixin
fi