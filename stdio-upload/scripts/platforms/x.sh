#!/bin/bash

# X (Twitter) 视频上传脚本 (stdio 模式)
# 被 upload.sh 调用: upload_video_x <视频路径> <标题>
# 或单独运行: ./x.sh <视频路径> [标题]

PLATFORM_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PLATFORM_SCRIPT_DIR/../human.sh"

STDIO_SERVER="${STDIO_SERVER:-/Users/azm/Library/pnpm/global/5/node_modules/mcp-chrome-bridge/dist/mcp/mcp-server-stdio.js}"

# 检测是否被 source（作为函数被调用）
_is_sourced() {
    [[ "${BASH_SOURCE[0]}" != "${0}" ]]
}

# MCP 调用函数 - 带重试
mcp_call() {
    local JSON="$1"
    local max_retries=5
    local retry=0
    local RESULT=""

    while [ $retry -lt $max_retries ]; do
        if [ $retry -gt 0 ]; then
            lsof -i :12306 2>/dev/null | grep -v PID | awk '{print $2}' | head -1 | xargs kill -9 2>/dev/null
            sleep 2
        fi

        RESULT=$(echo "$JSON" | node "$STDIO_SERVER" 2>&1)

        if echo "$RESULT" | grep -q '"jsonrpc"'; then
            if echo "$RESULT" | grep -q 'ECONNREFUSED\|Failed to connect'; then
                retry=$((retry + 1))
                continue
            fi
            echo "$RESULT"
            return 0
        fi

        retry=$((retry + 1))
        sleep 2
    done

    echo "$RESULT"
    return 1
}

# X 平台视频上传函数
upload_video_x() {
    local video_path="$1"
    local title="$2"

    echo "============================================"
    echo "X 平台视频上传脚本 (stdio模式)"
    echo "视频路径: $video_path"
    echo "标题: $title"
    echo "============================================"

    # 检查视频文件
    if [ ! -f "$video_path" ]; then
        echo "错误: 视频文件不存在: $video_path"
        return 1
    fi

    # 清理端口
    lsof -i :12306 2>/dev/null | grep -v PID | awk '{print $2}' | head-1 | xargs kill -9 2>/dev/null
    sleep 2

    echo ""
    echo "=== 初始化 MCP ==="
    INIT_JSON='{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"cli","version":"1.0"}},"id":1}'
    mcp_call "$INIT_JSON" > /dev/null

    echo ""
    echo "=== 打开 X 首页 ==="
    NAVIGATE_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_navigate","arguments":{"url":"https://x.com/home"}},"id":2}'
    RESULT=$(mcp_call "$NAVIGATE_JSON")

    if ! echo "$RESULT" | grep -q '"isError":false'; then
        echo "导航失败"
        return 1
    fi
    echo "导航: OK"

    # 模拟人类阅读页面
    human_read_page_delay

    echo ""
    echo "=== 点击发帖按钮 ==="
    human_reaction_delay
    # X 首页发帖按钮 - aria-label="发帖"
    CLICK_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_click_element","arguments":{"selector":"a[aria-label=\"发帖\"]","selectorType":"css"}},"id":3}'
    CLICK_RESULT=$(mcp_call "$CLICK_JSON")
    echo "点击发帖按钮结果: $CLICK_RESULT"

    # 等待弹框出现
    echo "等待弹框出现 (2秒)..."
    sleep 2

    echo ""
    echo "=== 弹框中点击视频上传图标 ==="
    human_reaction_delay
    # 弹框内视频上传按钮 - SVG video grid icon (blue)
    # 用 Python 构造 JSON 避免 bash 引号嵌套问题
    CLICK_VIDEO_JSON=$(python3 -c "
import json
d = {
    'jsonrpc': '2.0',
    'method': 'tools/call',
    'params': {
        'name': 'chrome_click_element',
        'arguments': {
            'selector': 'svg path[d=\"M3 5.5C3 4.119 4.119 3 5.5 3h13C19.881 3 21 4.119 21 5.5v13c0 1.381-1.119 2.5-2.5 2.5h-13C4.119 21 3 19.881 3 18.5v-13zM5.5 5c-.276 0-.5.224-.5.5v9.086l3-3 3 3 5-5 3 3V5.5c0-.276-.224-.5-.5-.5h-13zM19 15.414l-3-3-5 5-3-3-3 3V18.5c0 .276.224.5.5.5h13c.276 0 .5-.224.5-.5v-3.086zM9.75 7C8.784 7 8 7.784 8 8.75s.784 1.75 1.75 1.75 1.75-.784 1.75-1.75S10.716 7 9.75 7z\"]',
            'selectorType': 'css'
        }
    },
    'id': 4
}
print(json.dumps(d))
")
    CLICK_VIDEO_RESULT=$(mcp_call "$CLICK_VIDEO_JSON")
    echo "点击视频上传按钮结果: $CLICK_VIDEO_RESULT"

    # 模拟人类延迟
    human_random_delay

    echo ""
    echo "=== 上传视频文件 ==="
    # 用 Python 构造 JSON 避免 bash 引号嵌套
    ESCAPED_PATH=$(echo "$video_path" | sed 's/"/\\"/g')
    UPLOAD_JSON=$(python3 -c "
import json
d = {
    'jsonrpc': '2.0',
    'method': 'tools/call',
    'params': {
        'name': 'chrome_upload_file',
        'arguments': {
            'selector': 'input[data-testid="fileInput"]',
            'filePath': '$ESCAPED_PATH'
        }
    },
    'id': 5
}
print(json.dumps(d))
")
    UPLOAD_RESULT=$(mcp_call "$UPLOAD_JSON")
    echo "上传结果: $UPLOAD_RESULT"

    echo "等待视频处理 (3秒)..."
    sleep 3

    echo ""
    echo "=== 滚动页面 ==="
    human_random_delay
    SCROLL_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_computer","arguments":{"action":"scroll","scrollDirection":"down","scrollAmount":3}},"id":6}'
    mcp_call "$SCROLL_JSON" > /dev/null
    human_scroll_wait
    echo "滚动完成"

    echo ""
    echo "=== 检查页面状态 ==="
    human_reaction_delay
    READ_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_read_page","arguments":{"filter":"interactive"}},"id":7}'
    PAGE_RESULT=$(mcp_call "$READ_JSON")
    echo "页面: $PAGE_RESULT"

    # 填写标题 - X 使用 Draft.js 编辑器，通过修改 span[data-text="true"] 来注入内容
    echo ""
    echo "=== 填写标题 ==="
    human_reaction_delay

    # JS 代码写临时文件，避免 bash 引号嵌套问题 (100% 参照 douyin.sh/baijiahao.sh 风格)
    JS_TEMP=$(mktemp)
    cat > "$JS_TEMP" << 'JSEOF'
var dialog = document.querySelector('[role="dialog"]');
var editable = dialog && dialog.querySelector('[contenteditable="true"]');
var contentsArr = editable && editable.getElementsByTagName('div');
var contents = null;
for (var i = 0; i < contentsArr.length; i++) {
    if (contentsArr[i].getAttribute('data-contents') === 'true') {
        contents = contentsArr[i];
        break;
    }
}
if (contents) {
    var block = contents.querySelector('[data-block="true"]');
    var offsetSpan = block && block.querySelector('span[data-offset-key]');
    var textSpan = offsetSpan && offsetSpan.querySelector('span[data-text="true"]');
    
    if (textSpan) {
        textSpan.textContent = '';
        textSpan.textContent = 'TITLE_PLACEHOLDER';
        contents.dispatchEvent(new Event('input', {bubbles: true}));
    } else {
        var br = offsetSpan && offsetSpan.querySelector('br[data-text="true"]');
        if (br) {
            var newSpan = document.createElement('span');
            newSpan.setAttribute('data-text', 'true');
            newSpan.textContent = 'TITLE_PLACEHOLDER';
            br.parentNode.replaceChild(newSpan, br);
            contents.dispatchEvent(new Event('input', {bubbles: true}));
        }
    }
}
JSEOF

    # 替换标题占位符
    ESCAPED_TITLE=$(echo "$title" | sed 's/'\''/\\'\''/g')
    sed -i '' "s/TITLE_PLACEHOLDER/$ESCAPED_TITLE/g" "$JS_TEMP"

    # 用 Python 构造 JSON (避免 bash 引号嵌套问题, 100% 参照 baijiahao.sh 风格)
    JS_JSON=$(python3 -c "
import json
with open('$JS_TEMP', 'r') as f:
    code = f.read()
d = {'jsonrpc': '2.0', 'method': 'tools/call', 'params': {'name': 'chrome_javascript', 'arguments': {'code': code}}, 'id': 8}
print(json.dumps(d, ensure_ascii=False))
")
    rm -f "$JS_TEMP"

    FILL_RESULT=$(mcp_call "$JS_JSON")
    echo "填写结果: $FILL_RESULT"

    echo ""
    echo "============================================"
    echo "X 平台视频上传流程完成!"
    echo "============================================"
}

# 如果直接运行此脚本
if ! _is_sourced; then
    if [ -z "$1" ]; then
        echo "用法: $0 <视频路径> [标题]"
        exit 1
    fi
    upload_video_x "$1" "$2"
fi
