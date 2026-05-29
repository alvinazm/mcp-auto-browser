# 抖音视频上传完整指南

## 核心经验总结

经过多次尝试和失败，最终成功上传视频。以下是关键发现和注意事项：

---

## 一、关键成功要素

### 1. 使用 MCP 客户端的正确方式

**错误做法**：每个环节创建新的客户端连接
```javascript
// ❌ 错误 - 会导致 "Already connected to a transport" 错误
await createClient(); // 环节3
await createClient(); // 环节4 - 失败！
```

**正确做法**：整个流程只使用一个客户端连接
```javascript
// ✅ 正确 - 单进程单连接
const client = new Client({ name: 'Mcp Chrome Proxy', ... });
const transport = new StreamableHTTPClientTransport(new URL(config.url), {});
await client.connect(transport);

// 所有操作使用同一个 client
await client.callTool({ name: 'chrome_navigate', ... });
await client.callTool({ name: 'chrome_upload_file', ... });
await client.callTool({ name: 'chrome_read_page', ... });

// 最后关闭
await client.close();
```

### 2. 等待时间

| 环节 | 等待时间 | 原因 |
|------|----------|------|
| 导航后 | `human_read_page_delay` | 模拟人类阅读页面的随机延迟（3~6秒） |
| 点击后 | `human_reaction_delay` | 模拟人类反应延迟（1~3秒） |
| 上传后 | 2 秒 | 等待视频上传完成触发页面变化 |
| 滚动后 | `human_scroll_wait` | 模拟滚动后的停顿（0.5~1.5秒） |
| 封面上传后 | 3 秒 | 等待封面处理完成 |
| 封面弹框出现 | 3 秒 | 等待弹框 DOM 渲染完成 |

### 3. 不要启动 MCP 服务

**错误做法**：尝试在脚本中启动 MCP 服务
```bash
# ❌ 错误
node mcp-server-stdio.js &
```

**正确做法**：MCP 服务应该已经由 Chrome 扩展启动
```bash
# ✅ 正确 - 检查服务是否已运行
if lsof -i :12306 | grep -q LISTEN; then
    echo "MCP 服务已在运行"
else
    echo "请先在 Chrome 中激活 mcp-chrome 扩展"
fi
```

---

## 二、完整上传流程

### 步骤 1: 确认前置条件

1. **Chrome 浏览器已登录抖音账号** - 打开 creator.douyin.com 确认
2. **MCP 服务已运行** - 检查端口 12306：
   ```bash
   lsof -i :12306 | grep LISTEN
   ```
3. **视频文件存在** - 检查文件路径

### 步骤 2: 执行上传脚本

```bash
cd /Users/azm/MyProject/auto-browser/video-upload
./scripts/platforms/douyin.sh /path/to/video.mp4 "视频标题"
```

### 步骤 3: 流程说明

```
环节 1: 检查 MCP 服务 (端口 12306)
       ↓
环节 2: 初始化 MCP 连接
       ↓
环节 3: 导航到上传页面
       ↓
环节 4: 人类阅读延迟 (3~6秒) ← 使用 human.sh 模拟
       ↓
环节 5: 点击"上传视频"按钮
       ↓
环节 6: 人类反应延迟 (1~3秒)
       ↓
环节 7: 上传视频文件 (选择器: input[type="file"])
       ↓
环节 8: 等待视频上传 (2秒)
       ↓
环节 9: 滚动页面 + 人类滚动延迟
       ↓
环节 10: 人类反应延迟 (1~3秒)
       ↓
环节 11: 填写标题
       ↓
环节 12: 如有封面 → 点击选择封面 → 人类延迟 → 上传封面 → 等待 3 秒 → 点击完成
```

---

## 三、关键代码片段

### MCP 客户端初始化（仅供参考，当前脚本使用 stdio 模式直接发 JSON-RPC）

> 注意：当前成功的脚本不使用 Node.js SDK，而是通过 bash 直接发 JSON-RPC 到 stdio 服务器。以下代码仅用于理解底层通信原理。

```javascript
const { Client } = require('@modelcontextprotocol/sdk/client/index.js');
const { StreamableHTTPClientTransport } = require('@modelcontextprotocol/sdk/client/streamableHttp.js');

// 设置模块路径
process.env.NODE_PATH = '/Users/azm/Library/pnpm/global/5/.pnpm/@modelcontextprotocol+sdk@1.29.0_zod@3.25.76/node_modules:' + process.env.NODE_PATH;
require('module')._initPaths();

// 加载配置
const config = JSON.parse(fs.readFileSync('/path/to/stdio-config.json', 'utf8'));

// 创建客户端（只创建一次）
const client = new Client({ name: 'Mcp Chrome Proxy', version: '1.0.0' }, { capabilities: {} });
const transport = new StreamableHTTPClientTransport(new URL(config.url), {});
await client.connect(transport);
```

### 上传视频

```javascript
const uploadResult = await client.callTool({ 
    name: 'chrome_upload_file', 
    arguments: { 
        selector: 'input[type="file"]',  // 必须使用这个选择器
        filePath: '/path/to/video.mp4'
    }
}, undefined, { timeout: 180000 });
```

### 检查上传结果

```javascript
// 上传后等待 2 秒
await new Promise(r => setTimeout(r, 2000));

// 检查页面是否出现标题输入框
const pageResult = await client.callTool({ 
    name: 'chrome_read_page', 
    arguments: { filter: 'interactive' }
}, undefined, { timeout: 30000 });

const content = JSON.stringify(pageResult.content);
if (content.includes('textbox') && content.includes('标题')) {
    console.log('✓ 上传成功');
}
```

---

## 四、常见错误及解决

### 错误 1: "Already connected to a transport"

**原因**：多次创建客户端连接

**解决**：整个流程只使用一个客户端连接

### 错误 2: "视频文件不存在"

**原因**：文件路径错误或文件不存在

**解决**：
```bash
# 检查文件是否存在
ls -la /path/to/video.mp4
```

### 错误 3: "MCP 服务未运行"

**原因**：MCP 服务未启动

**解决**：
1. 打开 Chrome 扩展管理页面
2. 找到 mcp-chrome 扩展
3. 点击连接，确保显示"服务运行中 (端口: 12306)"

### 错误 4: 上传后页面没有跳转

**原因**：等待时间不够或页面元素选择器不对

**解决**：确认上传完成后等待 2 秒再执行后续操作

---

## 五、相关文件路径

| 文件 | 路径 |
|------|------|
| 平台脚本 | `/Users/azm/MyProject/auto-browser/video-upload/scripts/platforms/douyin.sh` |
| human.sh 函数库 | `/Users/azm/MyProject/auto-browser/video-upload/scripts/human.sh` |
| stdio 配置 | `/Users/azm/Library/pnpm/global/5/node_modules/mcp-chrome-bridge/dist/mcp/stdio-config.json` |
| MCP SDK | `/Users/azm/Library/pnpm/global/5/.pnpm/@modelcontextprotocol+sdk@1.29.0_zod@3.25.76/node_modules/` |

---

## 六、重要提示

1. **不要多次创建客户端** - 这是导致 "Already connected" 错误的根本原因
2. **使用 human.sh 模拟人类行为** - 所有延迟通过 human_read_page_delay、human_reaction_delay、human_random_delay、human_scroll_wait 模拟，比固定 sleep 更自然
3. **MCP 服务由扩展管理** - 不需要在脚本中启动
4. **使用正确的选择器** - `input[type="file"]` 是上传视频的关键选择器
5. **上传后等待 2 秒** - 视频上传触发页面变化后再执行后续操作

---

## 七、stdio 模式脚本（当前成功方案）

### 为什么这次成功了？

2024年4月14日更新的脚本采用了**纯 bash + stdio 模式**，与之前的 node.js MCP SDK 方案不同。成功原因如下：

#### 1. 每次 MCP 调用都是独立的进程

```bash
# 每次调用都启动新的 node 进程
mcp_call() {
    RESULT=$(echo "$JSON" | node "$STDIO_SERVER" 2>&1)
}
```

每次调用都会：
1. 清理端口残留进程
2. 启动新的 node 进程
3. 发送 JSON-RPC 请求
4. 获取响应后进程退出

#### 2. 端口清理机制

```bash
cleanup() {
    lsof -i :12306 2>/dev/null | grep -v PID | awk '{print $2}' | head -1 | xargs kill -9 2>/dev/null
    sleep 2
}
```

每次调用前都清理端口，确保没有残留进程占用端口。

#### 3. 重试机制

```bash
while [ $retry -lt $max_retries ]; do
    if [ $retry -gt 0 ]; then
        cleanup
    fi
    RESULT=$(echo "$JSON" | node "$STDIO_SERVER" 2>&1)
    
    if echo "$RESULT" | grep -q 'ECONNREFUSED\|Failed to connect'; then
        retry=$((retry + 1))
        continue
    fi
    return 0
done
```

如果遇到连接错误，会自动重试（最多5次）。

#### 4. 完整的流程设计

| 步骤 | 操作 | 说明 |
|------|------|------|
| 1 | cleanup | 清理端口残留进程 |
| 2 | initialize | 初始化 MCP 连接 |
| 3 | navigate | 打开上传页面 |
| 4 | human_read_page_delay | 人类阅读延迟 (3~6秒) |
| 5 | click_element | 点击"上传视频"按钮 |
| 6 | human_reaction_delay | 人类反应延迟 (1~3秒) |
| 7 | upload_file | 上传视频文件 |
| 8 | sleep 2 | 等待视频上传触发页面变化 |
| 9 | scroll + human_scroll_wait | 滚动页面并模拟人类滚动 |
| 10 | human_reaction_delay | 人类反应延迟 (1~3秒) |
| 11 | fill_or_select | 填写标题 |
| 12 | click_element (封面) | 点击"选择封面"按钮 |
| 13 | sleep 3 | 等待弹框出现 |
| 14 | click_element (坐标) | 点击弹框内"上传封面" |
| 15 | upload_file (封面) | 上传封面文件 |
| 16 | sleep 3 | 等待封面处理 |
| 17 | click_element | 点击"完成"按钮 |

#### 5. 与之前失败方案的区别

| 对比项 | 之前的 node.js 方案 | 现在的 stdio 方案 |
|--------|---------------------|-------------------|
| 连接方式 | HTTP 客户端 (StreamableHTTPClientTransport) | 标准输入输出 (stdio) |
| 进程模型 | 单进程内多个 HTTP 请求 | 每次调用独立进程 |
| 端口占用 | 需要端口持续监听 | 每次启动后释放 |
| 错误恢复 | 容易出现 "Already connected" | 每次重试都是全新进程 |
| 连续运行 | 第二次会失败 | 可以连续成功 |

### stdio 模式的核心优势

1. **无状态**：每次调用都是独立的，不存在状态残留
2. **自动清理**：进程退出后自动释放资源
3. **简单可靠**：不需要管理长连接
4. **易于调试**：每次调用都可以单独测试

### 当前脚本路径

```bash
/Users/azm/MyProject/auto-browser/video-upload/scripts/platforms/douyin.sh
```

### 使用方法

```bash
cd /Users/azm/MyProject/auto-browser/video-upload
./scripts/platforms/douyin.sh /path/to/video.mp4 "视频标题" /path/to/cover.jpg
```

参数说明：
- 第1个参数：视频文件路径（必填）
- 第2个参数：视频标题（可选，默认"测试视频上传"）
- 第3个参数：封面图片路径（可选，不填则不上传封面）

---

## 八、封面上传流程（2024年4月新增）

### 流程概述

封面上传需要**两步**：
1. 点击页面上的"选择封面"按钮 → 打开弹框
2. 在弹框中点击"上传封面" → 上传图片文件 → 点击完成

### 封面上传完整步骤

```
步骤1: 点击"选择封面"按钮 (CSS选择器: div.title-wA45Xd)
       ↓
步骤2: 等待 3 秒让弹框出现
       ↓
步骤3: 点击弹框中的"上传封面"按钮 (坐标或点击上传图标)
       ↓
步骤4: 等待 2 秒
       ↓
步骤5: 上传封面文件 (选择器: div.upload-BvM5FF input.semi-upload-hidden-input)
       ↓
步骤6: 等待 3 秒让封面上传完成
       ↓
步骤7: 点击"完成"按钮 (CSS选择器: button.secondary-zU1YLr)
```

### 关键 CSS 选择器

| 元素 | 选择器 | 说明 |
|------|--------|------|
| 选择封面按钮 | `div.title-wA45Xd` | 横封面选择按钮 |
| 封面上传区域容器 | `div.upload-BvM5FF` | 弹框内上传区域 |
| 封面文件输入 | `div.upload-BvM5FF input.semi-upload-hidden-input` | 隐藏的文件输入框 |
| 完成按钮 | `button.secondary-zU1YLr` | 关闭弹框的按钮 |

**注意**：弹框内的"上传封面"按钮目前使用固定坐标 `(x:1097, y:610)` 点击，因为弹框内的按钮选择器不稳定。CSS 选择器 `div.upload-BvM5FF input.semi-upload-hidden-input` 仅用于文件上传步骤。

### 弹框中的关键元素

从页面元素中可以看到弹框包含：
- `generic "设置横封面"` - 标题
- `generic "上传封面"` - 上传按钮文本
- `generic "点击上传文件或拖拽文件到这里"` - 上传区域提示
- `button "设置竖封面"` - 切换到竖封面按钮
- `button.secondary-zU1YLr` - 完成按钮

### 带封面上传的使用方法

```bash
./scripts/platforms/douyin.sh /path/to/video.mp4 "视频标题" /path/to/cover.jpg
```

参数说明：
- 第1个参数：视频文件路径（必填）
- 第2个参数：视频标题（可选，默认"测试视频上传"）
- 第3个参数：封面图片路径（可选，不填则不上传封面）

### 常见问题

**问题1：弹框没有打开**
- 检查选择器是否正确（使用 `div.title-wA45Xd` 选择器）
- 可能需要先滚动页面让"选择封面"按钮可见

**问题2：找不到 file input**
- 弹框打开后，页面上会有隐藏的 file input 元素
- 使用精确的选择器 `div.upload-BvM5FF input.semi-upload-hidden-input`

**问题3：封面上传到了其他地方**
- 因为页面上可能有多个 input[type="file"] 元素
- 必须使用精确的选择器定位到弹框内的 input

---

## 九、技术实现细节

### stdio 模式脚本结构

```bash
#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../human.sh"

# 清理端口
cleanup() {
    lsof -i :12306 2>/dev/null | grep -v PID | awk '{print $2}' | head -1 | xargs kill -9 2>/dev/null
    sleep 2
}

# MCP 调用函数 - 带重试
mcp_call() {
    local JSON="$1"
    # 每次调用启动新的 node 进程，请求完成后进程退出
    RESULT=$(echo "$JSON" | node "$STDIO_SERVER" 2>&1)
}

# 主流程
cleanup
mcp_call "$INIT_JSON"           # 初始化
mcp_call "$NAVIGATE_JSON"       # 导航
human_read_page_delay           # 人类阅读延迟
mcp_call "$CLICK_JSON"          # 点击上传按钮
human_reaction_delay            # 人类反应延迟
mcp_call "$UPLOAD_JSON"          # 上传视频
sleep 2                          # 等待视频上传
mcp_call "$SCROLL_JSON"          # 滚动页面
human_scroll_wait
human_reaction_delay
mcp_call "$FILL_JSON"           # 填写标题
# 如有封面 → 点击选择封面 → sleep 3 → 点击上传 → 上传文件 → sleep 3 → 点击完成
```

### 为什么用 stdio 模式而不是 HTTP 模式

| 对比项 | HTTP 模式 | stdio 模式 |
|--------|-----------|------------|
| 连接方式 | StreamableHTTPClientTransport | 管道输入输出 |
| 进程模型 | 单进程长连接 | 每次调用独立进程 |
| 连续运行 | 第二次会失败 | 可以连续成功 |
| 资源管理 | 需要手动关闭 | 进程退出自动释放 |

### 核心优势

1. **无状态**：每次调用都是独立的，不存在状态残留
2. **自动清理**：进程退出后自动释放资源
3. **简单可靠**：不需要管理长连接
4. **易于调试**：每次调用都可以单独测试