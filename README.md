<p align="center">
<img width="1014" height="620" alt="PixPin_2026-03-10_18-49-55" src="https://github.com/user-attachments/assets/efdb14cb-c2cf-4e2d-9df7-5b5e30db9161" />
</p>

# OpenClaw Chat Gateway

**现代化、生产级的 OpenClaw 全功能 Web 客户端**

[简体中文](#简体中文) | [English](#english)

---

## 简体中文

**OpenClaw Chat Gateway** 是一款专为 OpenClaw 生态打造的生产级 Web 客户端。它为高级用户提供了一套完整的“智能体沙盒”管理方案，结合极致的响应式界面，让您的 OpenClaw 体验步入全新次元。

### 🌟 核心亮点

- **🤖 多智能体，全 UI 界面配置**：支持多智能体快速创建与管理，通过全 UI 可视化界面完成所有配置逻辑。彻底**告别手动修改 JSON 和 Markdown 文件**。
- **📉 独立模型配置 & 极大节约 Token**：每个智能体可独立配置不同的模型，结合完全隔离的工作空间（Workspace）和独立配置文件，**精准控制模型分流，极大减少了由于背景重叠导致的 Token 浪费**。
- **📱 极致的手机移动端优化**：深度适配移动端屏幕与交互逻辑，响应式设计丝滑顺畅，**操作体验几乎与原生 APP 无异**。

### 🆕 v2.0 重点更新

- **👥 新增团队模式，多智能体协同工作**：支持创建团队，让多个智能体围绕同一任务分工协作，配合独立运行时工作区与消息链路，更贴合 OpenClaw 多智能体协作最佳实践。
- **🧭 浏览器检测强化**：增强浏览器健康检查、自愈与配置检测能力，帮助浏览器相关能力更稳定启动、更容易排障。
- **📚 历史分页优化**：聊天记录再多也不再依赖整页重载，长会话加载更轻量，滚动与恢复体验更顺畅。
- **🧠 模型设置升级**：支持默认主模型、全局故障转移模型，以及为单个智能体单独设置故障转移链路。
- **🧩 端点设置与模型设置合并优化**：端点测试、模型发现、模型管理集中到一处，配置流程更简洁。
- **🛡️ 对话深度与收尾稳定性优化**：重点修复消息丢失、长回复被截断、终态收敛不稳定等问题，复杂任务场景更可靠。
- **✍️ 最后一轮对话支持修改与重生成**：可以围绕当前最新一轮回复继续调整，提高反复迭代效率。
- **🌐 多语种设置**：支持 `简体中文 / 繁體中文 / English`，主要界面与功能已覆盖多语言资源。

### ✨ 深度功能
- **🗝️ 智能体完全隔离 (Sandboxing)**：独立工作区、独立记忆。每个角色拥有专属的 `SOUL.md` 和 `USER.md`，彻底告别对话污染。
- **🖼️ 工业级预览体验**：集成 LibreOffice 渲染能力，完美支持 Word, PPT, Excel, PDF 等复杂文档在线预览，还原真实排版。
- **🚀 深度原生集成**：在对话窗口直接运行 `/status`、`/help` 等底层指令，实时反馈系统状态。
- **🔄 真实版本管理与检查更新**：版本号统一由仓库根版本维护，“关于系统”页面可读取真实版本并检查 GitHub 最新发布。

<p align="center">
  <img src="docs/screenshots/agent_config.png" width="45%" />

</p>

### 🚀 快速开始
> [!IMPORTANT]
> 本项目须安装在安装了 OpenClaw 的主机上，且必须是 **原生安装**（非 Docker）。支持 **Linux** 和 **macOS** 系统。

#### 📥 一键安装

**默认端口 3115**
```bash
curl -fsSL https://raw.githubusercontent.com/liandu2024/OpenClaw-Chat-Gateway/main/install.sh | bash
```

**自定义端口部署 (例如 8080)**
```bash
curl -fsSL https://raw.githubusercontent.com/liandu2024/OpenClaw-Chat-Gateway/main/install.sh | bash -s 8080
```

<details>
<summary>🍎 macOS 用户注意</summary>

macOS 使用 `launchd` 管理服务（而非 Linux 的 systemd），安装脚本已自动适配。安装完成后可通过以下命令管理服务：

```bash
# 查看服务状态
launchctl list | grep clawui

# 查看日志
cat /tmp/clawui-3115.log
cat /tmp/clawui-3115-err.log

# 停止服务
launchctl unload ~/Library/LaunchAgents/com.clawui-3115.plist

# 启动服务
launchctl load ~/Library/LaunchAgents/com.clawui-3115.plist
```

</details>

#### 🆙 无损升级
```bash
curl -fsSL https://raw.githubusercontent.com/liandu2024/OpenClaw-Chat-Gateway/main/update.sh | bash
```

#### 🗑️ 彻底卸载
```bash
curl -fsSL https://raw.githubusercontent.com/liandu2024/OpenClaw-Chat-Gateway/main/uninstall.sh | bash
```

---

### 📱 移动端预览
精心打磨的移动端细节，不仅是响应式，更是沉浸式。

<p align="center">
  <img src="docs/screenshots/mobile_sidebar.jpg" width="45%" />
  <img src="docs/screenshots/mobile_chat.jpg" width="45%" />
</p>

---

### 💡 提示：预览增强
如果您需要预览 Word, PPT, Excel 等文档，请安装 LibreOffice：

**Linux:**
```bash
sudo apt update && sudo apt install libreoffice -y
```

**macOS:**
```bash
brew install --cask libreoffice
```

### 💬 社群与支持
- **Telegram 群**: [安格视界 (AngeWorld)](https://t.me/angeworld2024)
- **资源站**: [安格超市 (Ange Market)](https://blog.angeworld.cc/market/)
- **芝麻开门**: [按需付费 AI 接口，官方 1/10 价格](https://ai.opendoor.cn)
- **超级门户**: [订阅付费 AI 接口，量大管饱的订阅制](https://ai.superdoor.top)

---

## English

**OpenClaw Chat Gateway** is a production-grade Web client designed specifically for the OpenClaw ecosystem. It provides a complete "Agent Sandboxing" management solution for advanced users, combined with a cutting-edge responsive interface to take your OpenClaw experience to a new dimension.

### 🌟 Core Highlights

- **🤖 Multi-Agent, Full UI Configuration**: Supports rapid creation and management of multi-agents through a fully visualized UI interface. Say goodbye to **manually editing JSON and Markdown files**.
- **📉 Isolated Model Configuration & Significant Token Savings**: Each agent can be independently configured with different models. Combined with completely isolated Workspaces and independent configuration files, it **precisely controls model routing and significantly reduces Token waste caused by background overlap**.
- **📱 Ultimate Mobile Optimization**: Deeply adapted to mobile screens and interaction logic, with a smooth responsive design. The **user experience is almost indistinguishable from a native app**.

### 🆕 What’s New in v2.0

- **👥 New Team mode for multi-agent collaboration**: Create a team and let multiple agents work on the same task with clearer role division, isolated runtime workspaces, and a collaboration flow that better matches OpenClaw multi-agent best practices.
- **🧭 Stronger browser diagnostics**: Improved browser health checks, recovery flow, and configuration validation to make browser-based capabilities easier to start and troubleshoot.
- **📚 Better history pagination**: Large chat histories no longer rely on heavy full-page reloads, making long conversations smoother to load and recover.
- **🧠 Upgraded model settings**: Configure a default primary model, global fallback models, and per-agent fallback chains.
- **🧩 Simpler endpoint + model management**: Endpoint testing, model discovery, and model management are now more unified and easier to operate.
- **🛡️ Better conversation depth and finalization stability**: Focused fixes for missing messages, truncated long replies, and unstable final-state completion in complex tasks.
- **✍️ Edit and regenerate the latest reply**: The latest round of conversation can be refined or regenerated more naturally.
- **🌐 Multilingual settings**: Supports `简体中文 / 繁體中文 / English` across the main UI and settings flows.

### ✨ In-Depth Features
- **🗝️ Complete Agent Isolation (Sandboxing)**: Independent workspaces and memory. Each character has its own `SOUL.md` and `USER.md`, completely eliminating conversation pollution.
- **🖼️ Industrial-Grade Preview Experience**: Integrated with LibreOffice rendering capabilities, it perfectly supports online previews of complex documents such as Word, PPT, Excel, and PDF, preserving the original layout.
- **🚀 Deep Native Integration**: Run low-level commands like `/status` and `/help` directly in the chat window for real-time system status feedback.
- **🔄 Real version management and update checks**: The app version is now unified from the root project version, and the About page can read the real current version and check the latest GitHub Release.

<p align="center">
  <img src="docs/screenshots/agent_config.png" width="45%" />
</p>

### 🚀 Quick Start
> [!IMPORTANT]
> This project must be installed on a host where OpenClaw is already installed, and it must be a **native installation** (not Docker). Both **Linux** and **macOS** are supported.

#### 📥 One-Click Installation

**Default port 3115**
```bash
curl -fsSL https://raw.githubusercontent.com/liandu2024/OpenClaw-Chat-Gateway/main/install.sh | bash
```

**Custom port deployment (e.g., 8080)**
```bash
curl -fsSL https://raw.githubusercontent.com/liandu2024/OpenClaw-Chat-Gateway/main/install.sh | bash -s 8080
```

<details>
<summary>🍎 macOS Notes</summary>

macOS uses `launchd` for service management (instead of Linux's systemd). The install script automatically adapts. After installation, manage the service with:

```bash
# Check service status
launchctl list | grep clawui

# View logs
cat /tmp/clawui-3115.log
cat /tmp/clawui-3115-err.log

# Stop service
launchctl unload ~/Library/LaunchAgents/com.clawui-3115.plist

# Start service
launchctl load ~/Library/LaunchAgents/com.clawui-3115.plist
```

</details>

#### 🆙 Non-Destructive Upgrade
```bash
curl -fsSL https://raw.githubusercontent.com/liandu2024/OpenClaw-Chat-Gateway/main/update.sh | bash
```

#### 🗑️ Complete Uninstallation
```bash
curl -fsSL https://raw.githubusercontent.com/liandu2024/OpenClaw-Chat-Gateway/main/uninstall.sh | bash
```

---

### 📱 Mobile Preview
Meticulously crafted mobile details, providing not just responsiveness, but immersion.

<p align="center">
  <img src="docs/screenshots/mobile_sidebar.jpg" width="45%" />
  <img src="docs/screenshots/mobile_chat.jpg" width="45%" />
</p>

---

### 💡 Tip: Enhanced Preview
If you need to preview documents like Word, PPT, or Excel, install LibreOffice:

**Linux:**
```bash
sudo apt update && sudo apt install libreoffice -y
```

**macOS:**
```bash
brew install --cask libreoffice
```

### 💬 Community & Support
- **Telegram Group**: [安格视界 (AngeWorld)](https://t.me/angeworld2024)
- **Resource Site**: [安格超市 (Ange Market)](https://blog.angeworld.cc/market/)
- **AI Interface**: [按需付费 AI 接口，官方 1/10 价格](https://ai.opendoor.cn)
- **AI Interface**: [订阅付费 AI 接口，量大管饱的订阅制](https://ai.superdoor.top)
