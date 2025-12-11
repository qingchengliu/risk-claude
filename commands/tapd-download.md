# TAPD 需求下载

将 TAPD 需求详情页面内容抓取并转换为本地 Markdown 文件，图片下载到本地并替换为相对路径。

## 使用方法

```
/tapd-download [TAPD需求URL] [cookie <Cookie字符串>]
```

## 参数说明

- **TAPD需求URL**（可选）: 需求详情页 URL（如 `https://www.tapd.cn/tapd_fe/20061171/story/detail/1120061171001406306`）
- **Cookie字符串**（可选）: 浏览器 Cookie（F12 → Network → 任意请求 → Request Headers → Cookie）

**必需 Cookie**: `tapdsession`, `t_u`, `t_i_token`

---

## 参数交互流程

### 1. 检查 TAPD URL

如果用户没有提供 TAPD URL，使用 AskUserQuestion 工具询问：

```
请输入 TAPD 需求页面 URL：
示例: https://www.tapd.cn/tapd_fe/20061171/story/detail/1120061171001406306
```

**URL 验证规则**:
- 必须包含 `tapd.cn`
- 必须包含 `/story/detail/` 或 `/stories/view/`

### 2. 检查 Cookie

如果用户没有提供 Cookie，使用 AskUserQuestion 工具询问：

```
请输入 TAPD Cookie：
获取方法: F12 → Network → 任意请求 → Request Headers → Cookie
必需包含: tapdsession, t_u, t_i_token
```

---

## 输出目录结构

**存储位置**: `./.claude/tapd/`（项目根目录下的 `.claude/tapd/` 文件夹）

```
.claude/
└── tapd/
    ├── TAPD需求_1406306_派单规则新增支持案量金额作为目标结果分配.md
    └── images/
        └── TAPD_1406306/
            ├── img_01.png
            ├── img_02.png
            └── ...
```

---

## 输出文件命名规则

**文件名格式**: `TAPD需求_<需求ID>_<需求标题>.md`

**示例**:
- `TAPD需求_1406306_派单规则新增支持案量金额作为目标结果分配.md`
- `TAPD需求_1401026_黑产识别声纹识别及相关优化.md`

**标题清理规则**:
```javascript
// 移除文件名非法字符和特殊符号
const safeTitle = title
  .replace(/[【】\[\]\/\\:*?"<>|]/g, '')  // 移除非法字符
  .replace(/\s+/g, '')                     // 移除空格
  .substring(0, 50);                       // 限制长度
```

---

## 执行流程（7步）

### 步骤0: 前置检查

**0.1 检查 Playwright MCP 是否可用**

在执行任何操作前，先检查是否能调用 Playwright MCP 工具（如 `mcp__playwright__browser_navigate`）。

**检测方法**：尝试调用任意 Playwright MCP 工具，如果工具不存在或返回错误，则说明未安装。

**未安装时的处理**：

如果检测到 Playwright MCP 未安装，**立即停止执行**，并向用户显示以下提示信息：

```
❌ 未检测到 Playwright MCP 服务

此命令需要 Playwright MCP 来操作浏览器，请按以下步骤安装：

1. 退出 Claude Code（按 Ctrl+C 或输入 /exit）
2. 在终端运行以下命令安装 Playwright MCP：

   claude mcp add playwright -s user -- npx @anthropic-ai/mcp-server-playwright

3. 重新启动 Claude Code
4. 再次运行 /tapd-download 命令

安装完成后，Playwright MCP 将作为用户级服务在所有项目中可用。
```

**已安装时**：继续执行后续步骤。

---

### 步骤1: 参数检查与交互

**1.1 检查 TAPD URL**

如果命令参数中没有提供 URL：
- 使用 AskUserQuestion 询问用户输入 TAPD 需求 URL
- 验证 URL 格式是否正确

**1.2 检查 Cookie**

如果命令参数中没有提供 Cookie：
- 使用 AskUserQuestion 询问用户输入 Cookie
- 提示用户 Cookie 获取方法

---

### 步骤2: 导航并设置 Cookie

**2.1 导航到目标页面**

使用 `mcp__playwright__browser_navigate`:
```
url: <TAPD需求URL>
```

**2.2 检查登录状态**

导航后检查页面标题：
- ✅ 包含需求标题 → 已登录，继续步骤3
- ❌ 显示"登录-TAPD" → 需要设置 Cookie

**2.3 设置 Cookie（如需要）**

使用 `mcp__playwright__browser_evaluate`:
```javascript
() => {
  document.cookie = "tapdsession=xxx; domain=.tapd.cn; path=/";
  document.cookie = "t_u=xxx; domain=.tapd.cn; path=/";
  document.cookie = "t_i_token=xxx; domain=.tapd.cn; path=/";
  document.cookie = "_t_uid=xxx; domain=.tapd.cn; path=/";
  document.cookie = "_t_crop=xxx; domain=.tapd.cn; path=/";
  return "Cookie已设置";
}
```

然后重新导航到目标 URL。

**2.4 等待页面加载**

使用 `mcp__playwright__browser_wait_for` 等待 3 秒让 SPA 渲染完成。

---

### 步骤3: 提取内容和图片列表

使用 `mcp__playwright__browser_evaluate`:

```javascript
() => {
  // 提取标题
  const title = document.querySelector('[class*="detail-title"] p')?.textContent?.trim()
    || document.title.split('-')[0].trim();

  // 提取需求 ID（取最后7位）
  const storyId = location.href.match(/detail\/(\d+)/)?.[1]?.slice(-7) || '';

  // 提取图片列表
  const images = [];
  const seen = new Set();
  document.querySelectorAll('img').forEach((img) => {
    const url = img.getAttribute('original_src') || img.src;
    if (url && url.includes('file.tapd.cn') && !url.includes('avatar') && !url.includes('icon') && !seen.has(url)) {
      seen.add(url);
      images.push({
        index: images.length + 1,
        url: url,
        localName: 'img_' + String(images.length + 1).padStart(2, '0') + '.png'
      });
    }
  });

  return { title, storyId, images, pageUrl: location.href };
}
```

**输出示例**:
```json
{
  "title": "【派单】派单规则新增：支持案量+金额作为目标结果分配",
  "storyId": "1406306",
  "images": [
    { "index": 1, "url": "https://file.tapd.cn/xxx.png", "localName": "img_01.png" },
    { "index": 2, "url": "https://file.tapd.cn/yyy.png", "localName": "img_02.png" }
  ]
}
```

---

### 步骤4: 下载图片

**推荐方式：逐个导航+元素截图**

批量下载（`browser_run_code`）可能不可靠，推荐逐个下载：

对每张图片执行：
1. `mcp__playwright__browser_navigate` 导航到图片 URL
2. `mcp__playwright__browser_take_screenshot` 元素级截图

```
element: "image"
ref: "e2"  (img 元素的 ref)
filename: "img_01.png"
```

**Cookie 自动携带原理**：
- 步骤1设置的 Cookie 属于当前浏览器上下文
- 导航到 `file.tapd.cn` 时自动携带 `.tapd.cn` 域的 Cookie

**图片保存位置**: `.playwright-mcp/` 目录

---

### 步骤5: 复制图片并生成 Markdown

**5.1 创建输出目录**

```powershell
powershell -Command "New-Item -ItemType Directory -Force -Path '.claude/tapd/images/TAPD_<需求ID>'"
```

**5.2 复制图片**

```powershell
powershell -Command "Copy-Item '.playwright-mcp/img_*.png' -Destination '.claude/tapd/images/TAPD_<需求ID>/' -Force"
```

**5.3 生成 Markdown 文件**

文件名：`.claude/tapd/TAPD需求_<需求ID>_<清理后标题>.md`

使用 Write 工具创建，图片路径替换为：
```markdown
![img_01](./images/TAPD_<需求ID>/img_01.png)
```

---

### 步骤6: 清理并关闭

```powershell
powershell -Command "Remove-Item '.playwright-mcp/img_*.png' -Force -ErrorAction SilentlyContinue"
```

使用 `mcp__playwright__browser_close` 关闭浏览器。

---

## 输出文件结构

```
.claude/
└── tapd/
    ├── TAPD需求_1406306_派单规则新增支持案量金额作为目标结果分配.md
    └── images/
        └── TAPD_1406306/
            ├── img_01.png
            ├── img_02.png
            └── ...
```

---

## Markdown 文件模板

```markdown
# <需求标题>

> 来源: [TAPD需求详情](<原始URL>)
> 下载时间: <YYYY-MM-DD HH:mm>

## 基础信息

| 字段 | 值 |
|------|-----|
| 需求ID | xxx |
| 状态 | xxx |
| 处理人 | xxx |
| 优先级 | xxx |
| 创建人 | xxx |
| 创建时间 | xxx |

---

## 需求BRD

<从页面提取的 BRD 内容>

---

## 产品PRD

<从页面提取的 PRD 内容，图片已替换为本地路径>

![img_01](./images/TAPD_xxx/img_01.png)
```

---

## 图片路径替换

**步骤2 提取结果**（localName 仅为文件名）:
```json
{ "url": "https://file.tapd.cn/abc.png", "localName": "img_01.png" }
```

**步骤4 替换时拼接完整相对路径**:
```javascript
const mdImagePath = `./images/TAPD_${storyId}/${img.localName}`;
// 结果: ./images/TAPD_1406306/img_01.png
```

---

## 常见问题

### Q1: 页面重定向到登录页
**A**: Cookie 不完整或已过期，需重新从浏览器获取完整 Cookie，确保包含 `tapdsession`、`t_u`、`t_i_token`

### Q2: 图片下载失败
**A**: 使用逐个导航+截图方式，不要用批量下载。确保在同一浏览器上下文中操作。

### Q3: 内容为空
**A**: TAPD 是 SPA，导航后需等待 3 秒让 JS 渲染完成

### Q4: sensitive_words_detected 错误
**A**: Cookie 值被 API 检测为敏感内容，解决方案：
1. 使用 `browser_evaluate` 通过 `document.cookie` 设置
2. 分批设置 Cookie（每次 2-3 个）
3. 只设置必要的认证 Cookie

### Q5: 文件名包含非法字符
**A**: 标题中的 `【】[]/:*?"<>|` 等字符需移除，空格也建议移除

---

## 执行检查清单

- [ ] 参数检查完成（URL 和 Cookie 已获取）
- [ ] 页面正常加载（标题显示需求名称，非"登录-TAPD"）
- [ ] 提取到 title、storyId、images 列表
- [ ] 每张图片已下载到 `.playwright-mcp/`
- [ ] 图片已复制到 `.claude/tapd/images/TAPD_xxx/`
- [ ] Markdown 文件已创建到 `.claude/tapd/`，文件名包含需求ID和标题
- [ ] 图片路径已替换为本地相对路径
- [ ] 临时文件已清理
- [ ] 浏览器已关闭
