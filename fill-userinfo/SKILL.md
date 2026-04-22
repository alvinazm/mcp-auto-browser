---
name: fill-user-info
description: 在网页上自动填写个人信息（姓名、邮箱、手机、学历、城市等）
trigger: 填写个人信息、填写表单、个人信息、fill info、fill form
---

# 自动填写个人信息

在网页上自动填写个人信息。

## 执行流程

**重要：必须使用 bash mcp_call 函数调用 MCP，禁止直接使用 MCP 工具！**

> ❌ 禁止：直接调用 `chrome_read_page`、`chrome_fill_or_select` 等 MCP 工具
> ✅ 必须：通过 bash `mcp_call` 函数发送 JSON-RPC 请求

### 步骤 1：定义 MCP 调用函数

**重要：每次调用前必须杀掉进程并启动新进程！不需要初始化！**

```bash
# stdio 服务器路径
STDIO_SERVER=/Users/azm/Library/pnpm/global/5/node_modules/mcp-chrome-bridge/dist/mcp/mcp-server-stdio.js

# 杀掉所有残留进程（每次调用前必须执行）
mcp_call() {
    # 杀掉所有 mcp-chrome-bridge 残留进程
    ps aux | grep -i mcp-chrome-bridge | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null || true
    sleep 1
    
    # 启动新进程并调用
    echo '$1' | node $STDIO_SERVER 2>&1
}
```

### 步骤 2：读取个人信息

从 `references/userinfo.md` 读取用户信息（姓名、邮箱、手机、学历、学校等）

### 步骤 3：读取页面

使用 mcp_call 调用 chrome_read_page 获取页面表单元素：

```bash
mcp_call '{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_read_page\",\"arguments\":{\"filter\":\"interactive\"},\"id\":1}}'
```

> ⚠️ 注意：不需要 initialize！直接调用工具即可。

### 步骤 4：识别字段

根据输入框的 placeholder、label、id 等属性匹配字段

### 步骤 5：填写信息

根据字段类型选择正确的填写方式

## 字段类型与填写方式

### 1. 普通文本输入框
直接使用 `chrome_fill_or_select` 填写：

```bash
# 姓名、邮箱等普通输入框
chrome_fill_or_select(selector="input[id='name']", value="安泽民")
chrome_fill_or_select(selector="input[id='email']", value="anzemin@qq.com")
```

### 2. 手机号输入框（带国家区号）

手机号通常由 **国家区号下拉框 + 手机号输入框** 组成：

```
┌─────────┬──────────────┐
│ +86     │ 18257115677  │
│ [combobox] [textbox]  │
└─────────┴──────────────┘
```

**填写步骤**：
1. 找到国家区号选择框（通常是 combobox 类型，带有 "+86" 或类似文本）
2. 找到手机号输入框（通常是 textbox，有 placeholder 如"请输入"、"number picker"等）
3. 先点击国家区号选择框激活
4. 然后填写手机号输入框

```bash
# 步骤1: 点击国家区号选择框（找带有 +86 或国家代码的 combobox）
chrome_click_element(selector="combobox[id*='mobile']")

# 步骤2: 填写手机号（找 textbox 类型的输入框）
chrome_fill_or_select(selector="textbox[placeholder*='请输入']", value="18257115677")
```

### 3. 下拉选择框（Combobox）

**核心原则**：combobox 不是普通输入框，直接 `fill` 填入文字只会显示文字，**不会选中选项**。

必须分两步：
```
步骤1: 用 fill 填入文字（触发下拉列表）
       ↓
步骤2: 读取页面，获取新出现的 option
       ↓
步骤3: 点击 option 完成选择
```

**填写步骤**：

```bash
# 步骤1: 用 fill 填入文字，触发下拉列表（不要直接 fill 后就以为选中了）
chrome_fill_or_select(selector="combobox[id*='city']", value="杭州")

# 步骤2: 立即读取页面，获取下拉选项
chrome_read_page()

# 步骤3: 在结果中找 option 元素（text 包含目标值）
# 选择器方式：找 listbox 下的 option
chrome_click_element(selector="option[text*='杭州']")
# 或使用 ref（ref 会随页面刷新变化，尽量用 selector）
chrome_click_element(ref="选项的ref")
```

**常见 combobox 字段**（都需要两步）：
- 城市（下拉选择）
- 国家/地区（下拉选择）
- 学历/学位（下拉选择）
- 学校（搜索选择）
- 专业（搜索选择）
- 专业类别（下拉选择）

**判断依据**：页面元素显示为 `combobox` 类型的，都是下拉选择框。

## 字段匹配规则

### 常用选择器

| 字段 | 选择器 |
|------|--------|
| 姓名 | `input[placeholder*="姓名"]`, `input[id*="name"]` |
| 邮箱 | `input[placeholder*="邮箱"]`, `input[type="email"]` |
| 手机号 | `textbox[placeholder*="手机"]`, `textbox[placeholder*="number"]` |
| 国家区号 | `combobox[id*="mobile"]`, `combobox` (带有 +86) |
| 国家 | `select[id*="country"]`, `combobox[id*="nationality"]` |
| 城市 | `combobox[id*="city"]`, `input[id*="city"]` |
| 学历 | `select[id*="education"]`, `combobox[id*="degree"]` |
| 学校 | `combobox[id*="school"]` |
| 院系 | `input[id*="academy"]`, `input[id*="department"]` |
| 专业 | `combobox[id*="major"]`, `input[id*="major"]` |

### 通用匹配逻辑

1. **元素类型优先**：先读取页面，识别元素是 `textbox` / `combobox` / `select`
2. **id 属性**：`input[id="name"]`, `combobox[id="city"]`
3. **placeholder**：`input[placeholder*="姓名"]`, `combobox[placeholder*="请选择"]`
4. **type 属性**：`input[type="email"]`, `textbox[placeholder*="number"]`

### 元素类型与填写方式对照表

| 页面显示类型 | 填写方式 | 示例 |
|------------|--------|------|
| textbox | 直接 `fill` | 姓名、邮箱、手机号输入框 |
| combobox | 必须两步：`fill` + 点击 `option` | 城市、国家、学历、学校、专业 |
| select | 必须两步：`fill` + 点击 `option` | 下拉选择 |
| textbox + combobox 组合 | 先点 combobox，再填 textbox | 手机号（国家区号 + 手机号） |

## 个人信息字段

从 `references/userinfo.md` 读取，包含以下字段：

| 字段 | 键名 | 说明 |
|------|------|------|
| 姓名 | name, 姓名 | 用户姓名 |
| 邮箱 | email, 邮箱 | 邮箱地址 |
| 手机 | phone, 手机, 电话, mobile | 手机号码 |
| 国家 | country, 国家, 国籍 | 国家 |
| 家庭所在城市 | home_city, 家庭城市 | 家庭所在城市 |
| 学校所在城市 | school_city, 学校城市 | 学校所在城市 |
## 前置条件

1. mcp-chrome 扩展已连接（端口 12306）
2. 已打开目标网页（不需要重新导航）

## mcp_call 函数（必须使用）

**关键：每次调用前必须杀掉进程并启动新进程！不需要 initialize！**

### stdio 服务器路径

```bash
STDIO_SERVER=/Users/azm/Library/pnpm/global/5/node_modules/mcp-chrome-bridge/dist/mcp/mcp-server-stdio.js
```

### MCP 调用函数（正确实现）

```bash
mcp_call() {
    # 杀掉所有 mcp-chrome-bridge 残留进程（每次调用前必须执行）
    ps aux | grep -i mcp-chrome-bridge | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null || true
    sleep 1
    
    # 启动新进程并调用（不需要 initialize，直接调用工具）
    echo '$1' | node $STDIO_SERVER 2>&1
}
```

### 使用流程（每次任务必须按此顺序执行）

```bash
# 1. 定义路径和函数
STDIO_SERVER=/Users/azm/Library/pnpm/global/5/node_modules/mcp-chrome-bridge/dist/mcp/mcp-server-stdio.js

mcp_call() {
    ps aux | grep -i mcp-chrome-bridge | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null || true
    sleep 1
    echo '$1' | node $STDIO_SERVER 2>&1
}

# 2. 读取页面（不需要 initialize！）
mcp_call '{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_read_page\",\"arguments\":{\"filter\":\"interactive\"},\"id\":1}}'

# 3. 填写信息
mcp_call '{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_fill_or_select\",\"arguments\":{\"ref\":\"ref_10\",\"value\":\"安泽民\"},\"id\":1}}'
```

### 常见错误

- **"Already connected"**: 每次调用都启动了新进程，必须先清理端口
- **"ECONNREFUSED"** / **"TypeError: fetch failed"**: 端口被占用或连接失败，增加重试逻辑
- **"Element is not visible"**: 元素不可见，可能需要先滚动到元素位置

## 个人信息文件位置

```
/Users/azm/MyProject/auto-browser/FillAI/fill-userinfo/references/userinfo.md
```

## 常见问题

**找不到输入框**：尝试多种选择器组合，先读取页面查看元素类型

**填写失败**：
- 确认页面元素可见，可能需要先滚动到元素位置
- 检查元素类型是否是 combobox，如果是必须两步选择

**手机号填写失败**：检查是否是 combobox + textbox 组合，先点击 combobox 再填 textbox

**下拉框无法选择**：
- 确认元素类型是 combobox 不是 textbox
- 必须分三步：`fill` 填文字 → `read_page` 获取选项 → `click` 点击选项

**combobox 填写了但没选中**：
- 这是最常见的错误！combobox 不能像 textbox 那样直接 fill 就选中
- 填入文字后只是显示了候选列表，还需要点击选项才能选中
- 填写完成后再读取页面确认是否已选中显示

**元素 ref 失效**：页面刷新后 ref 会变化，在同一页面操作时 ref 是稳定的

**点击空白处关闭下拉菜单**：填写完 combobox 后，如果要继续填写其他字段，可能需要先点击空白处关闭下拉菜单

**专业填写**：专业是 combobox 类型，需要：
1. 用 fill 填入专业名称（如"信息管理与信息系统"）
2. 读取页面获取选项
3. 点击选项完成选择

## 问题排查与解决总结

### 问题 1：MCP 连接 "Already connected" 错误

**现象**：第一次调用成功，后续调用失败，错误信息：
```
"Already connected to a transport. Call close() before connecting to a new transport"
```

**原因**：stdio 服务器每次启动都会创建新的客户端连接到 12306 端口。第一次调用后进程退出，但端口可能仍被占用，导致下次连接失败。

**解决方式**：每次调用前都清理端口 + 增加重试逻辑

```bash
mcp_call() {
    local JSON="$1"
    local max_retries=5
    local retry=0
    
    while [ $retry -lt $max_retries ]; do
        # 每次调用前清理端口
        lsof -i :12306 2>/dev/null | grep -v PID | awk '{print $2}' | xargs kill -9 2>/dev/null || true
        sleep 2
        
        RESULT=$(echo "$JSON" | node "$STDIO_SERVER" 2>&1)
        
        if echo "$RESULT" | grep -q '"jsonrpc"'; then
            # 如果是连接错误，重试
            if echo "$RESULT" | grep -q 'TypeError: fetch failed\|ECONNREFUSED'; then
                retry=$((retry + 1))
                continue
            fi
            echo "$RESULT"
            return 0
        fi
        
        retry=$((retry + 1))
    done
}
```

### 问题 2："TypeError: fetch failed" / "ECONNREFUSED"

**现象**：连接被拒绝
```
Error: connect ECONNREFUSED 127.0.0.1:12306
```

**原因**：端口 12306 上的进程已经退出，但新进程还没启动完成

**解决方式**：增加重试逻辑，每次重试前清理端口并等待 2 秒

### 问题 3：combobox 填写后没有选中

**现象**：用 fill 填写了城市/学校/专业等字段，但页面没有选中显示

**原因**：combobox 类型不能像 textbox 那样直接 fill 就选中，填入文字后只是显示了候选列表

**解决方式**：
```bash
# 步骤1: 用 fill 填入文字，触发下拉列表
chrome_fill_or_select(selector="combobox[id='school']", value="浙江大学")

# 步骤2: 读取页面，获取下拉选项
chrome_read_page()

# 步骤3: 在结果中找 option 元素并点击
chrome_click_element(ref="选项的ref")
```

### 问题 4：填写时遇到 "Element is not visible"

**原因**：下拉菜单还开着，影响后续字段填写

**解决方式**：点击页面空白处关闭下拉菜单，再继续填写
```bash
chrome_click_element(coordinates={"x":100,"y":100})
```

### 完整填写流程示例（阿里校招简历）

```bash
# 1. 姓名 (textbox - 直接 fill)
mcp_call 'chrome_fill_or_select(ref="ref_10", value="安泽民")'

# 2. 邮箱 (textbox - 直接 fill)
mcp_call 'chrome_fill_or_select(ref="ref_15", value="anzemin@qq.com")'

# 3. 手机号 (combobox + textbox - 先点 combobox 再填 textbox)
mcp_call 'chrome_click_element(ref="ref_13")'  # 点击国家区号
mcp_call 'chrome_fill_or_select(ref="ref_14", value="18257115677")'

# 4. 国籍 (combobox - 三步)
mcp_call 'chrome_fill_or_select(ref="ref_11", value="中国")'
mcp_call 'chrome_read_page()'  # 获取选项
mcp_call 'chrome_click_element(ref="ref_35")'  # 点击"中国大陆"

# 5. 家庭城市 (combobox - 三步)
mcp_call 'chrome_fill_or_select(ref="ref_16", value="杭州")'
mcp_call 'chrome_read_page()'
mcp_call 'chrome_click_element(ref="ref_50")'

# 6. 学校城市 (combobox - 三步)
mcp_call 'chrome_fill_or_select(ref="ref_17", value="杭州")'
mcp_call 'chrome_read_page()'
mcp_call 'chrome_click_element(ref="ref_56")'

# 7. 学历 (combobox - 三步)
mcp_call 'chrome_fill_or_select(ref="ref_42", value="本科")'
mcp_call 'chrome_read_page()'
mcp_call 'chrome_click_element(ref="ref_64")'

# 8. 学校 (combobox - 三步)
mcp_call 'chrome_fill_or_select(ref="ref_45", value="浙江大学")'
mcp_call 'chrome_read_page()'
mcp_call 'chrome_click_element(ref="ref_70")'

# 9. 院系 (textbox - 直接 fill)
mcp_call 'chrome_fill_or_select(ref="ref_46", value="管理学院")'

# 10. 专业类别 (combobox - 三步)
mcp_call 'chrome_fill_or_select(ref="ref_51", value="管理学")'
mcp_call 'chrome_read_page()'
mcp_call 'chrome_click_element(ref="对应option的ref")'

# 11. 专业 (combobox - 三步)
mcp_call 'chrome_fill_or_select(ref="ref_52", value="信息管理与信息系统")'
mcp_call 'chrome_read_page()'
mcp_call 'chrome_click_element(ref="ref_87")'
```
