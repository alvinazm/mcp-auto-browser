# auto-browser

> 基于 MCP Chrome 的多平台视频自动上传工具，模拟真实用户操作，防止被平台识别为机器行为。


## 功能特性

- **7 大平台支持**：抖音、小红书、快手、百家号、B站、X (Twitter)、YouTube
- **人类行为模拟**：随机延迟、阅读时间、滚动模拟，规避平台检测
- **stdio 模式架构**：无状态、进程独立、自动重试，稳定可靠
- **零依赖部署**：纯 bash 脚本，只需 Node.js 和 Chrome
- **模块化设计**：统一入口 + 平台插件，新增平台只需新增一个 `.sh`

---

## 工作原理

```
┌─────────────────────────────────────────────────────┐
│  upload.sh                                          │
│  ├── human.sh          # 人类行为模拟函数库         │
│  └── platforms/                                     │
│       ├── douyin.sh    # 抖音                      │
│       ├── xiaohongshu.sh  # 小红书                  │
│       ├── kuaishou.sh  # 快手                      │
│       ├── baijiahao.sh # 百家号                    │
│       ├── bilibili.sh  # B站                       │
│       ├── x.sh         # X (Twitter)               │
│       └── youtube.sh   # YouTube                   │
└─────────────────────────────────────────────────────┘
                        │
                        ▼
            MCP Chrome stdio 模式
            (mcp-chrome-bridge)
                        │
                        ▼
              Chrome Browser
         (控制已登录的浏览器页面)
```

核心流程：

1. 初始化 MCP stdio 连接（自动清理端口、重试）
2. 导航到平台创作者后台
3. 模拟人类阅读页面（500–1200ms 随机延迟）
4. 滚动查找上传区域
5. 上传视频文件
6. 等待视频处理（8–10 秒）
7. 填写标题/描述
8. 封面上传（仅抖音支持）

---

## 前置条件

- **macOS**（其他系统脚本路径需调整）
- **Chrome 浏览器**
- **Node.js**（用于运行 MCP stdio server）
- **Chrome 已登录**目标平台创作者后台

### 安装 MCP Chrome 扩展

详细步骤见 [mcp-chrome 官方文档](https://github.com/hangwin/mcp-chrome/blob/master/README_zh.md)。

1. 下载 Chrome 扩展
   ```bash
   # 地址：https://github.com/hangwin/mcp-chrome/releases
   ```

2. 全局安装 `mcp-chrome-bridge`
   ```bash
   # npm
   npm install -g mcp-chrome-bridge

   # pnpm（推荐）
   pnpm config set enable-pre-post-scripts true
   pnpm install -g mcp-chrome-bridge
   # 如果 postinstall 未运行，手动注册：
   mcp-chrome-bridge register
   ```

3. 加载 Chrome 扩展
   - 打开 `chrome://extensions/`
   - 启用**开发者模式**
   - 点击**加载已解压的扩展程序**，选择下载的扩展文件夹
   - 点击扩展图标，点击**连接**，状态显示 `connected` 即成功

---

## 快速开始

```bash
# 进入脚本目录
cd /Users/azm/MyProject/auto-browser/video-upload/scripts

# 单平台上传统一入口
./upload.sh <平台> <视频路径> [标题] [封面路径]

# 示例
./upload.sh douyin /path/to/video.mp4 "我的视频标题"
./upload.sh xiaohongshu /path/to/video.mp4 "小红书标题"
./upload.sh kuaishou /path/to/video.mp4 "快手标题"
./upload.sh baijiahao /path/to/video.mp4 "百家号标题"
./upload.sh bilibili /path/to/video.mp4 "B站标题"
./upload.sh x /path/to/video.mp4 "X平台标题"
./upload.sh youtube /path/to/video.mp4 "YouTube标题"

# 同步到所有平台
./upload.sh all /path/to/video.mp4 "视频标题"

# 抖音带封面上传（封面仅抖音支持）
./upload.sh douyin /path/to/video.mp4 "标题" /path/to/cover.jpg
```

---

## 参数说明

| 参数 | 说明 | 必填 | 默认值 |
|------|------|------|--------|
| 平台 | 目标平台标识 | 是 | — |
| 视频路径 | 视频文件路径 | 是 | — |
| 标题 | 视频标题 | 否 | `"测试视频上传"` |
| 封面路径 | 封面图片路径 | 否 | —（仅抖音支持） |

---

## 平台支持详情

| 平台 | 标识 | 创作者后台 | 封面支持 |
|------|------|-----------|---------|
| 抖音 | `douyin` | creator.douyin.com | ✅ |
| 小红书 | `xiaohongshu` | creator.xiaohongshu.com | ❌ |
| 快手 | `kuaishou` | cp.kuaishou.com | ❌ |
| 百家号 | `baijiahao` | baijiahao.baidu.com | ❌ |
| B站 | `bilibili` | member.bilibili.com | ❌ |
| X | `x` | x.com | ❌ |
| YouTube | `youtube` | youtube.com | ❌ |

> 各平台详细选择器和流程见 [references/platform-selectors.md](video-upload/references/platform-selectors.md)

---

## 项目结构

```
auto-browser/
├── README.md
└── video-upload/
    ├── SKILL.md                        # AI Agent 技能文档
    ├── references/
    │   └── platform-selectors.md       # 各平台选择器参考
    ├── doc/
    │   └── douyin-video-upload.md     # 抖音上传详细指南
    └── scripts/
        ├── upload.sh                  # 统一入口脚本
        ├── human.sh                   # 人类行为模拟函数库
        └── platforms/                 # 平台插件
            ├── douyin.sh
            ├── xiaohongshu.sh
            ├── kuaishou.sh
            ├── baijiahao.sh
            ├── bilibili.sh
            ├── x.sh
            └── youtube.sh
```

---

## 人类行为模拟

`human.sh` 提供以下函数，嵌入在每个平台脚本的关键操作前后：

| 函数 | 模拟行为 | 延迟范围 |
|------|---------|---------|
| `human_random_delay` | 随机操作间隔 | 300–700ms |
| `human_read_page_delay` | 页面阅读 | 500–1200ms |
| `human_reaction_delay` | 人类反应时间 | 300–800ms |
| `human_hover` | 悬停 | 100–300ms |
| `human_scroll_wait` | 滚动后等待 | 300–500ms |
| `human_scroll_down` | 向下滚动 + 等待 | — |
| `human_scroll_up` | 向上滚动 + 等待 | — |

---

## 常见问题

### MCP 连接失败

先确认 Chrome 扩展已连接（扩展 popup 显示 `connected`），然后检查端口：

```bash
lsof -i :12306 | grep LISTEN
```

### 端口被占用

```bash
lsof -i :12306 | grep -v PID | awk '{print $2}' | xargs kill -9
```

### 上传失败

- 确认视频文件存在且路径正确
- 确认 Chrome 已登录目标平台创作者后台
- 平台可能更新了页面结构，见 [references/platform-selectors.md](video-upload/references/platform-selectors.md)

### 选择器失效

平台 UI 经常变化，选择器可能需要更新。可以在浏览器 DevTools Console 中手动测试：

```javascript
document.querySelector('input[type="file"]')
```

---

## 技术细节

### stdio 模式 vs HTTP 模式

| 对比项 | HTTP 模式 | stdio 模式（当前） |
|--------|-----------|-------------------|
| 连接方式 | StreamableHTTPClientTransport | 管道输入输出 |
| 进程模型 | 单进程长连接 | 每次调用独立进程 |
| 连续运行 | 第二次可能失败 | 可连续稳定运行 |
| 资源管理 | 需手动关闭 | 进程退出自动释放 |

### 为什么 stdio 模式更可靠

1. **无状态**：每次 MCP 调用是独立的，不存在连接残留
2. **自动清理**：进程退出后自动释放端口
3. **内置重试**：连接失败自动重试最多 5 次
4. **独立调试**：每次调用可单独测试

---

## License

MIT
