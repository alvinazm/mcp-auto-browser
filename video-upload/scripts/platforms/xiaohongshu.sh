#!/bin/bash

# 小红书视频上传脚本 (HTTP 模式)
# 被 upload.sh 调用: upload_video_xiaohongshu <视频路径> <标题>
# 或单独运行: ./xiaohongshu.sh <视频路径> [标题]

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

# 小红书视频上传函数
upload_video_xiaohongshu() {
    local video_path="$1"
    local title="$2"

    echo "============================================"
    echo "小红书视频上传脚本 (HTTP模式)"
    echo "视频路径: $video_path"
    echo "标题: $title"
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
    NAVIGATE_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_navigate","arguments":{"url":"https://creator.xiaohongshu.com/publish/publish?source=official&from=menu&target=video"}},"id":2}'
    RESULT=$(mcp_call "$NAVIGATE_JSON")

    if ! echo "$RESULT" | grep -q '"isError":false'; then
        echo "导航失败"
        return 1
    fi
    echo "导航: OK"
    sleep 5

    # 滚动页面，让上传按钮可见
    echo ""
    echo "=== 滚动页面 ==="
    SCROLL_BEFORE_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_computer","arguments":{"action":"scroll","scrollDirection":"down","scrollAmount":3}},"id":3}'
    mcp_call "$SCROLL_BEFORE_JSON" > /dev/null
    human_read_page_delay

    echo "=== 上传视频文件 ==="
    human_read_page_delay
    ESCAPED_PATH=$(echo "$video_path" | sed 's/"/\\"/g')
    UPLOAD_JSON="{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_upload_file\",\"arguments\":{\"selector\":\"input[type=\\\"file\\\"]\",\"filePath\":\"$ESCAPED_PATH\"}},\"id\":3}"
    UPLOAD_RESULT=$(mcp_call "$UPLOAD_JSON")
    echo "上传结果: $UPLOAD_RESULT"

    echo "等待视频处理 (2秒)..."
    sleep 2

    echo ""
    echo "=== 滚动页面 ==="
    SCROLL_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_computer","arguments":{"action":"scroll","scrollDirection":"down","scrollAmount":3}},"id":4}'
    mcp_call "$SCROLL_JSON" > /dev/null
    echo "滚动完成"

    echo "=== 检查页面状态 ==="
    READ_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_read_page","arguments":{"filter":"interactive"}},"id":5}'
    PAGE_RESULT=$(mcp_call "$READ_JSON")
    echo "页面: $PAGE_RESULT"

    # 填写标题
    echo ""
    echo "=== 填写标题 ==="
    ESCAPED_TITLE=$(echo "$title" | sed 's/"/\\"/g')
    FILL_JSON="{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_fill_or_select\",\"arguments\":{\"selector\":\"input[placeholder*=\\\"标题\\\"]\",\"value\":\"$ESCAPED_TITLE\"}},\"id\":6}"
    FILL_RESULT=$(mcp_call "$FILL_JSON")
    echo "填写: $FILL_RESULT"


    echo ""
    echo "============================================"
    echo "上传流程完成!"
    echo "============================================"
}

# 如果直接运行此脚本
if ! _is_sourced; then
    if [ -z "$1" ]; then
        echo "用法: $0 <视频路径> [标题]"
        exit 1
    fi
    upload_video_xiaohongshu "$1" "$2"
fi