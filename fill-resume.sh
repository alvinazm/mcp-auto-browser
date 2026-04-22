#!/bin/bash

# 阿里云招聘简历填写脚本 (stdio 模式)
# 用法: ./fill-resume.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/human.sh"

# 用户信息文件
USERINFO_FILE="/Users/azm/MyProject/auto-browser/FillAI/fill-userinfo/references/userinfo.md"

# 读取用户信息
read_userinfo() {
    # 解析 userinfo.md 文件
    NAME=$(grep "姓名" "$USERINFO_FILE" | sed 's/.*| //' | sed 's/^ *//')
    EMAIL=$(grep "邮箱" "$USERINFO_FILE" | sed 's/.*| //' | sed 's/^ *//')
    PHONE=$(grep "手机" "$USERINFO_FILE" | sed 's/.*| //' | sed 's/^ *//')
    COUNTRY=$(grep "国家" "$USERINFO_FILE" | sed 's/.*| //' | sed 's/^ *//')
    HOME_CITY=$(grep "家庭所在城市" "$USERINFO_FILE" | sed 's/.*| //' | sed 's/^ *//')
    SCHOOL_CITY=$(grep "学校所在城市" "$USERINFO_FILE" | sed 's/.*| //' | sed 's/^ *//')
    EDUCATION=$(grep "学历" "$USERINFO_FILE" | sed 's/.*| //' | sed 's/^ *//')
    SCHOOL=$(grep "学校 " "$USERINFO_FILE" | sed 's/.*| //' | sed 's/^ *//')
    DEPARTMENT=$(grep "院系" "$USERINFO_FILE" | sed 's/.*| //' | sed 's/^ *//')
    MAJOR=$(grep "专业" "$USERINFO_FILE" | sed 's/.*| //' | sed 's/^ *//')
}

STDIO_SERVER="/Users/azm/Library/pnpm/global/5/node_modules/mcp-chrome-bridge/dist/mcp/mcp-server-stdio.js"

# 清理端口
cleanup() {
    lsof -i :12306 2>/dev/null | grep -v PID | awk '{print $2}' | head -1 | xargs kill -9 2>/dev/null
    sleep 2
}

# MCP 调用函数
mcp_call() {
    local JSON="$1"
    local max_retries=5
    local retry=0
    local RESULT=""

    while [ $retry -lt $max_retries ]; do
        if [ $retry -gt 0 ]; then
            cleanup
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

echo "============================================"
echo "阿里云招聘简历填写"
echo "============================================"

# 读取用户信息
read_userinfo
echo "姓名: $NAME"
echo "邮箱: $EMAIL"
echo "手机: $PHONE"
echo "国家: $COUNTRY"
echo "学历: $EDUCATION"
echo "学校: $SCHOOL"
echo "院系: $DEPARTMENT"
echo "专业: $MAJOR"

# 主流程
cleanup

echo ""
echo "=== 初始化 MCP ==="
INIT_JSON='{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"cli","version":"1.0"}},"id":1}'
INIT_RESULT=$(mcp_call "$INIT_JSON")
echo "初始化: OK"

# 等待页面加载
human_read_page_delay

echo ""
echo "=== 读取页面 ==="
READ_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_read_page","arguments":{"filter":"interactive"}},"id":2}'
PAGE_RESULT=$(mcp_call "$READ_JSON")
echo "页面元素已读取"

# 检查页面字段并填写
# 注意：这里需要根据实际表单字段匹配

echo ""
echo "============================================"
echo "简历填写流程完成!"
echo "============================================"
