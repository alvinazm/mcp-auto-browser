#!/bin/bash

# 抖音视频上传脚本 (stdio 模式)
# 用法: ./upload.sh <视频文件路径> [标题] [封面图片路径]

VIDEO_PATH="$1"
TITLE="$2"
COVER_PATH="$3"

if [ -z "$VIDEO_PATH" ]; then
    echo "用法: $0 <视频文件路径> [标题] [封面图片路径]"
    echo "示例: ./upload.sh /Users/azm/Downloads/video.mp4 我的视频标题 /Users/azm/Downloads/cover.jpg"
    exit 1
fi

if [ ! -f "$VIDEO_PATH" ]; then
    echo "错误: 文件不存在 - $VIDEO_PATH"
    exit 1
fi

if [ -z "$TITLE" ]; then
    TITLE="视频标题"
fi

# MCP Chrome stdio 服务器路径
STDIO_SERVER="/Users/azm/Library/pnpm/global/5/node_modules/mcp-chrome-bridge/dist/mcp/mcp-server-stdio.js"

# 清理端口函数
cleanup() {
    lsof -i :12306 2>/dev/null | grep -v PID | awk '{print $2}' | head -1 | xargs kill -9 2>/dev/null
    sleep 2
}

# MCP 调用函数
mcp_call() {
    local JSON="$1"
    echo "$JSON" | node "$STDIO_SERVER"
}

# ========== 主流程 ==========

echo "=== 抖音视频上传 ==="
echo "视频: $VIDEO_PATH"
echo "标题: $TITLE"
if [ -n "$COVER_PATH" ]; then
    echo "封面: $COVER_PATH"
fi
echo ""

# 1. 打开上传页面
echo "步骤 1: 打开上传页面..."
cleanup
RESULT=$(mcp_call "{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_navigate\",\"arguments\":{\"url\":\"https://creator.douyin.com/creator-micro/content/upload\"}},\"id\":1}")
if echo "$RESULT" | grep -q '"isError":false'; then
    echo "✓ 页面已打开"
else
    echo "✗ 失败: $RESULT"
    exit 1
fi

sleep 2

# 2. 直接上传视频（使用选择器）
echo ""
echo "步骤 2: 上传视频文件..."
cleanup
RESULT=$(mcp_call "{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_upload_file\",\"arguments\":{\"filePath\":\"$VIDEO_PATH\",\"selector\":\"input[type=\\\"file\\\"]\"}},\"id\":1}")
if echo "$RESULT" | grep -q '"isError":false'; then
    echo "✓ 视频上传成功"
else
    echo "✗ 失败: $RESULT"
fi

# 3. 等待视频处理
echo ""
echo "步骤 3: 等待视频处理 (8秒)..."
sleep 8

# 4. 填写标题（使用选择器定位）
echo ""
echo "步骤 4: 填写标题..."
cleanup
RESULT=$(mcp_call "{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_fill_or_select\",\"arguments\":{\"selector\":\"input[placeholder*=\\\"标题\\\"]\",\"value\":\"$TITLE\"}},\"id\":1}")
if echo "$RESULT" | grep -q '"isError":false'; then
    echo "✓ 标题已填写"
else
    echo "✗ 失败: $RESULT"
fi

# 5. 选择封面（如果有封面图片）
if [ -n "$COVER_PATH" ] && [ -f "$COVER_PATH" ]; then
    echo ""
    echo "步骤 5: 选择封面..."
    cleanup
    # 点击"选择封面"按钮
    RESULT=$(mcp_call "{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_click_element\",\"arguments\":{\"selector\":\"div[class*=\\\"filter-\\\\"]\"}},\"id\":1}")
    if echo "$RESULT" | grep -q '"isError":false'; then
        echo "✓ 已点击选择封面"
    else
        echo "✗ 失败: $RESULT"
    fi
    
    sleep 1
    
    # 上传封面图片
    echo ""
    echo "步骤 6: 上传封面图片..."
    cleanup
    RESULT=$(mcp_call "{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_upload_file\",\"arguments\":{\"filePath\":\"$COVER_PATH\",\"selector\":\".semi-upload-drag-area input[type=\\\"file\\\"]\"}},\"id\":1}")
    if echo "$RESULT" | grep -q '"isError":false'; then
        echo "✓ 封面上传成功"
    else
        echo "✗ 失败: $RESULT"
    fi
    
    sleep 2
else
    echo ""
    echo "步骤 5: 跳过封面 (未提供封面图片)"
fi

# 7. 滚动到底部
echo ""
echo "步骤 7: 滚动到底部..."
cleanup
RESULT=$(mcp_call "{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_javascript\",\"arguments\":{\"code\":\"window.scrollTo(0, document.body.scrollHeight)\"}},\"id\":1}")
echo "✓ 已滚动"

sleep 1

# 8. 点击发布按钮（使用选择器）
echo ""
echo "步骤 8: 点击发布按钮..."
cleanup
RESULT=$(mcp_call "{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_click_element\",\"arguments\":{\"selector\":\".semi-button-primary:not(.semi-button-light)\"}},\"id\":1}")
if echo "$RESULT" | grep -q '"isError":false'; then
    echo "✓ 已点击发布按钮"
else
    # 尝试备用选择器
    cleanup
    RESULT=$(mcp_call "{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_click_element\",\"arguments\":{\"selector\":\"button.semi-button-primary\"}},\"id\":1}")
    if echo "$RESULT" | grep -q '"isError":false'; then
        echo "✓ 已点击发布按钮 (备用)"
    else
        echo "✗ 失败: $RESULT"
    fi
fi

echo ""
echo "=== 上传完成 ==="
echo "请在浏览器中查看发布结果"