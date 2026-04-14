#!/bin/bash

# 人类行为模拟函数库
# 用途：模拟人类操作行为，防止被识别为机器操作

# 随机延迟 300-700ms
human_random_delay() {
    local ms=$((300 + RANDOM % 400))
    sleep $(echo "scale=3; $ms/1000" | bc)
}

# 页面阅读延迟 500-1200ms
human_read_page_delay() {
    local ms=$((500 + RANDOM % 700))
    sleep $(echo "scale=3; $ms/1000" | bc)
}

# 反应时间 300-800ms
human_reaction_delay() {
    local ms=$((300 + RANDOM % 500))
    sleep $(echo "scale=3; $ms/1000" | bc)
}

# 悬停 100-300ms
human_hover() {
    local ms=$((100 + RANDOM % 200))
    sleep $(echo "scale=3; $ms/1000" | bc)
}

# 滚动后等待 300-500ms
human_scroll_wait() {
    local ms=$((300 + RANDOM % 200))
    sleep $(echo "scale=3; $ms/1000" | bc)
}

# 短延迟 100-200ms
human_short_delay() {
    local ms=$((100 + RANDOM % 100))
    sleep $(echo "scale=3; $ms/1000" | bc)
}

# 长延迟 1000-2000ms
human_long_delay() {
    local ms=$((1000 + RANDOM % 1000))
    sleep $(echo "scale=3; $ms/1000" | bc)
}

# 模拟打字输入延迟（每个字符 50-150ms）
human_typing_delay() {
    local ms=$((50 + RANDOM % 100))
    sleep $(echo "scale=3; $ms/1000" | bc)
}
