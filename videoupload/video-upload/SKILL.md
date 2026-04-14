---
name: douyin-video-upload
description: 在抖音创作者后台上传视频、填写标题、上传封面（包含人类行为模拟）
trigger: 抖音上传、视频发布、上传封面、douyin upload
---

# 抖音视频上传

在抖音创作者后台上传视频，包含人类行为模拟防止被识别为机器操作。

## 使用方式

```bash
# 仅上传视频和标题
/Users/azm/MyProject/auto-browser/videoupload/video-upload/scripts/upload.sh <视频路径> [标题]

# 上传视频、标题和封面
/Users/azm/MyProject/auto-browser/videoupload/video-upload/scripts/upload.sh <视频路径> [标题] [封面路径]
```

## 参数说明

| 参数 | 说明 | 必填 |
|------|------|------|
| 视频路径 | 要上传的视频文件路径 | 是 |
| 标题 | 视频标题，默认"测试视频上传" | 否 |
| 封面路径 | 封面图片路径（可选） | 否 |

## 执行流程

1. 清理端口，初始化 MCP
2. 导航到上传页面
3. 模拟人类阅读页面（500-1200ms）
4. 点击上传按钮
5. 模拟人类反应延迟（300-800ms）
6. 上传视频文件
7. 等待视频处理（8秒）
8. 滚动页面（模拟人类行为）
9. 检查页面状态，填写标题
10. 上传封面（如果有）：点击选择封面 → 弹框打开 → 上传封面 → 点击完成

## 关键选择器

| 元素 | 选择器 |
|------|--------|
| 上传视频按钮 | `button.semi-button` |
| 视频文件输入 | `input[type="file"]` |
| 标题输入框 | `input[placeholder*="填写作品标题"]` |
| 选择封面按钮 | `div.title-wA45Xd` |
| 封面上传输入 | `div.upload-BvM5FF input.semi-upload-hidden-input` |
| 完成按钮 | `button.secondary-zU1YLr` |

## 人类行为模拟

脚本使用 `human.sh` 库提供人类行为模拟：

- human_random_delay: 随机延迟 300-700ms
- human_read_page_delay: 页面阅读延迟 500-1200ms
- human_reaction_delay: 反应时间 300-800ms
- human_scroll_wait: 滚动后等待 300-500ms

每个关键操作前后都有随机延迟和滚动，模拟真实用户行为。

## 前置条件

1. Chrome 浏览器已登录抖音创作者后台
2. mcp-chrome 扩展已连接（端口 12306）

## 常见问题

**上传失败**：确认视频文件存在，路径正确

**封面没上传成功**：确认使用了正确的选择器 `div.upload-BvM5FF input.semi-upload-hidden-input`，不要用通用的 `input[type="file"]`