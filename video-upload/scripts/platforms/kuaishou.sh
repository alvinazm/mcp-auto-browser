#!/bin/bash

# 快手视频上传脚本
# 平台标识: kuaishou
# 创作者后台: https://cp.kuaishou.com/article/publish/video

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../human.sh"

# ========== 平台配置 ==========
PLATFORM="kuaishou"
PLATFORM_NAME="快手"
PLATFORM_URL="https://cp.kuaishou.com/article/publish/video?tabType=1"

# 文件选择器（按优先级排序）
FILE_SELECTORS=(
    'input[type="file"]'
    'input[type="file"][accept*="video"]'
    'input[type="file"][accept*="mp4"]'
    ".upload-input"
    "#upload-input"
    "[class*='upload']"
    "[class*='file-input']"
)

# 快手没有标题，用描述代替标题
DESCRIPTION_SELECTORS=(
    'textarea[placeholder*="作品描述"]'
    'textarea[placeholder*="智能文案"]'
    'textarea[placeholder*="描述"]'
    'textarea[placeholder*="简介"]'
    'textarea[placeholder*="说"]'
    'textarea[placeholder*="内容"]'
    'textarea[placeholder*="补充"]'
    'textarea[aria-label*="描述"]'
    'textarea[aria-label*="简介"]'
    'textarea[class*="desc"]'
    'textarea[class*="content"]'
    'textarea[class*="intro"]'
    'textarea[id*="desc"]'
    'textarea[id*="content"]'
    "textarea"
    'div[contenteditable="true"][placeholder*="描述"]'
    'div[contenteditable="true"][placeholder*="简介"]'
    'input[placeholder*="作品描述"]'
    'input[placeholder*="描述"]'
    'input[placeholder*="简介"]'
)

# ========== 平台特定函数 ==========

kuaishou_get_file_selectors() {
    echo "${FILE_SELECTORS[*]}"
}

kuaishou_get_description_selectors() {
    echo "${DESCRIPTION_SELECTORS[*]}"
}

# ========== 主上传流程 ==========

upload_video_kuaishou() {
    local video_path="$1"
    local title="$2"

    echo ""
    echo "=== 快手视频上传流程 ==="
    echo "视频: $video_path"
    echo "描述: $title"
    echo ""

    # 1. 清理端口并初始化 MCP
    cleanup_port
    init_mcp

    # 2. 导航到上传页面
    echo ""
    echo "=== 导航到上传页面 ==="
    navigate_to "$PLATFORM_URL"
    echo "导航: OK"

    # 3. 模拟人类阅读页面
    human_read_page_delay

    # 4. 滚动查找上传区域
    echo ""
    echo "=== 滚动页面查找上传区域 ==="
    human_scroll_down 2

    # 5. 上传视频文件
    echo ""
    echo "=== 上传视频文件 ==="
    upload_file_first_found "$video_path" "$(kuaishou_get_file_selectors)"
    echo "上传视频: OK"

    # 6. 等待视频处理
    echo "等待视频上传 (10秒)..."
    sleep 10

    # 7. 滚动页面
    echo ""
    echo "=== 滚动页面 ==="
    human_scroll_down 2

    # 8. 填写描述（快手没有标题，用描述代替）
    echo ""
    echo "=== 填写作品描述 ==="
    read_page_interactive
    fill_title_first_found "$title" "$(kuaishou_get_description_selectors)"

    echo ""
    echo "============================================"
    echo "快手视频上传流程完成!"
    echo "请在浏览器中确认发布状态"
    echo "============================================"
}