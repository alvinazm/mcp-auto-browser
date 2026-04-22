#!/bin/bash

# 视频上传统一入口脚本
# 支持多平台视频上传：抖音、小红书、快手、百家号、B站
# 用法: ./upload.sh <平台> <视频路径> [标题] [封面路径]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/human.sh"
source "$SCRIPT_DIR/utils.sh"

# ========== 使用说明 ==========
usage() {
    echo "视频上传脚本 - 多平台支持"
    echo ""
    echo "用法: $0 <平台> <视频路径> [标题] [封面路径]"
    echo ""
    echo "平台选项:"
    echo "  douyin       - 抖音"
    echo "  xiaohongshu - 小红书"
    echo "  kuaishou   - 快手"
    echo "  baijiahao  - 百家号"
    echo "  bilibili   - B站"
    echo ""
    echo "示例:"
    echo "  $0 douyin /path/video.mp4 \"我的标题\""
    echo "  $0 xiaohongshu /path/video.mp4 \"我的标题\""
    echo "  $0 douyin /path/video.mp4 \"我的标题\" /path/cover.jpg"
    echo ""
    exit 1
}

# ========== 参数检查 ==========
if [ -z "$1" ]; then
    usage
fi

PLATFORM="$1"
VIDEO_PATH="$2"
TITLE="${3:-测试视频上传}"
COVER_PATH="$4"

# 检查平台是否支持
if ! is_platform_supported "$PLATFORM"; then
    echo "错误: 不支持的平台 '$PLATFORM'"
    echo ""
    usage
fi

# 检查视频文件
if [ ! -f "$VIDEO_PATH" ]; then
    echo "错误: 视频文件不存在: $VIDEO_PATH"
    exit 1
fi

# 检查封面文件（如果有）
if [ -n "$COVER_PATH" ] && [ ! -f "$COVER_PATH" ]; then
    echo "错误: 封面文件不存在: $COVER_PATH"
    exit 1
fi

echo "============================================"
echo "视频上传脚本 (多平台版)"
echo "平台: $PLATFORM"
echo "视频: $VIDEO_PATH"
echo "标题: $TITLE"
if [ -n "$COVER_PATH" ]; then
    echo "封面: $COVER_PATH"
fi
echo "============================================"

# ========== 加载平台脚本 ==========
PLATFORM_SCRIPT="$SCRIPT_DIR/platforms/${PLATFORM}.sh"

if [ ! -f "$PLATFORM_SCRIPT" ]; then
    echo "错误: 平台脚本不存在: $PLATFORM_SCRIPT"
    exit 1
fi

source "$PLATFORM_SCRIPT"

# ========== 调用平台特定的上传函数 ==========
PLATFORM_UPLOAD_FUNC="upload_video_${PLATFORM}"

if [ -n "$COVER_PATH" ]; then
    # 抖音支持封面上传，其他平台暂不支持
    if [ "$PLATFORM" = "douyin" ]; then
        $PLATFORM_UPLOAD_FUNC "$VIDEO_PATH" "$TITLE" "$COVER_PATH"
    else
        echo "警告: 当前平台 $PLATFORM 不支持封面上传"
        $PLATFORM_UPLOAD_FUNC "$VIDEO_PATH" "$TITLE"
    fi
else
    $PLATFORM_UPLOAD_FUNC "$VIDEO_PATH" "$TITLE"
fi