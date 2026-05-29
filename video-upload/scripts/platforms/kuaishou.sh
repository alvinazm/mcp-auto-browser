#!/bin/bash

# 快手视频上传脚本 (HTTP 模式)
# 100% 参照 douyin.sh 的 MCP 处理方式

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

# ========== 快手视频上传函数 ==========
upload_video_kuaishou() {
    local video_path="$1"
    local title="$2"

    echo "============================================"
    echo "快手视频上传脚本 (HTTP模式)"
    echo "视频路径: $video_path"
    echo "描述: $title"
    echo "============================================"

    # 检查视频文件
    if [ ! -f "$video_path" ]; then
        echo "错误: 视频文件不存在: $video_path"
        return 1
    fi

    echo ""
    echo "=== 初始化 MCP ==="
    mcp_wait_ready || { echo "MCP 初始化失败"; return 1; }

    echo ""
    echo "=== 打开上传页面 ==="
    NAVIGATE_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_navigate","arguments":{"url":"https://cp.kuaishou.com/article/publish/video?tabType=1"}},"id":2}'
    RESULT=$(mcp_call "$NAVIGATE_JSON")

    if ! echo "$RESULT" | grep -q '"isError":false'; then
        echo "导航失败"
        return 1
    fi
    echo "导航: OK"

    # 模拟人类阅读页面
    human_read_page_delay

    echo ""
    echo "=== 上传视频文件 ==="
    human_read_page_delay
    ESCAPED_PATH=$(echo "$video_path" | sed 's/"/\\"/g')
    UPLOAD_JSON="{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_upload_file\",\"arguments\":{\"selector\":\"input[type=\\\"file\\\"]\",\"filePath\":\"$ESCAPED_PATH\"}},\"id\":4}"
    UPLOAD_RESULT=$(mcp_call "$UPLOAD_JSON")
    echo "上传结果: $UPLOAD_RESULT"

    echo "等待视频上传 (3秒)..."
    sleep 3

    echo ""
    echo "=== 滚动页面 ==="
    SCROLL_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_computer","arguments":{"action":"scroll","scrollDirection":"down","scrollAmount":3}},"id":4}'
    mcp_call "$SCROLL_JSON" > /dev/null
    human_scroll_wait
    echo "滚动: OK"

    echo ""
    echo "=== 填写作品描述 (JavaScript直接设置) ==="

    # 使用 JavaScript 直接设置 innerText
    ESCAPED_TITLE=$(echo "$title" | sed "s/'/\\\\'/g")

    JS_CODE="var el = document.getElementById('work-description-edit'); if(el) { el.innerText = '$ESCAPED_TITLE'; el.dispatchEvent(new Event('input', {bubbles:true})); }"
    JS_JSON="{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_javascript\",\"arguments\":{\"code\":\"$JS_CODE\"}},\"id\":6}"
    JS_RESULT=$(mcp_call "$JS_JSON")
    echo "JS设置: $JS_RESULT"

    echo ""
    echo "============================================"
    echo "快手视频上传流程完成!"
    echo "请在浏览器中确认发布状态"
    echo "============================================"
}

# 如果直接运行此脚本
if ! _is_sourced; then
    if [ -z "$1" ]; then
        echo "用法: $0 <视频路径> [标题] [封面路径]"
        exit 1
    fi
    # 直接运行时：video title cover
    upload_video_kuaishou "$1" "$2"
fi