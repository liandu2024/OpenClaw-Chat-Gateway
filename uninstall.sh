#!/bin/bash
set -e

# Configuration
INSTALL_DIR="$HOME/OpenClaw-Chat-Gateway"

# Detect OS
OS_TYPE="$(uname -s)"

# Terminal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 探测安装目录和数据目录
DB_PATH="$HOME/.clawui/clawui.sqlite"
WORKSPACE_BASE="$HOME/.openclaw"

if [ "$OS_TYPE" = "Darwin" ]; then
    SERVICE_DIR="$HOME/Library/LaunchAgents"
    SERVICES=$(ls $SERVICE_DIR/com.clawui-*.plist 2>/dev/null || true)
else
    SERVICE_DIR="$HOME/.config/systemd/user"
    SERVICES=$(ls $SERVICE_DIR/clawui-*.service 2>/dev/null || true)
    if [ -f "$SERVICE_DIR/clawui.service" ]; then
        SERVICES="$SERVICES $SERVICE_DIR/clawui.service"
    fi
fi

DETECTED_DIRS=""
for S_PATH in $SERVICES; do
    if [ "$OS_TYPE" = "Darwin" ]; then
        W_DIR=$(grep -A1 '<key>WorkingDirectory</key>' "$S_PATH" | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/' | sed 's|/backend$||')
    else
        W_DIR=$(grep "^WorkingDirectory=" "$S_PATH" | cut -d'=' -f2 | sed 's/ /\\ /g')
        W_DIR=$(dirname "$W_DIR")
    fi
    P_DIR="$W_DIR"
    if [ -d "$P_DIR" ]; then
        DETECTED_DIRS="$DETECTED_DIRS $P_DIR"
    fi
done

if [ -f "./uninstall.sh" ]; then
    DETECTED_DIRS="$DETECTED_DIRS $(pwd)"
fi

CLEAN_DIRS=$(echo "$DETECTED_DIRS $INSTALL_DIR" | tr ' ' '\n' | sort -u | grep -v "^$" || true)

# 动态探测工作区
TARGET_WORKSPACES=""

# 来源 1: 从 SQLite 数据库探测 (如果存在且有工具)
if [ -f "$DB_PATH" ] && command -v sqlite3 &>/dev/null; then
    AGENT_IDS=$(sqlite3 "$DB_PATH" "SELECT DISTINCT agentId FROM characters;" 2>/dev/null || true)
    for id in $AGENT_IDS; do
        if [ "$id" == "main" ]; then
            TARGET_WORKSPACES="$TARGET_WORKSPACES $WORKSPACE_BASE/workspace-main"
        else
            TARGET_WORKSPACES="$TARGET_WORKSPACES $WORKSPACE_BASE/workspace-$id"
        fi
    done
fi

# 来源 2: 从 openclaw.json 配置文件探测
OPENCLAW_CONFIG="$WORKSPACE_BASE/openclaw.json"
if [ -f "$OPENCLAW_CONFIG" ]; then
    if command -v jq &>/dev/null; then
        JSON_WS=$(jq -r '.agents.list[].workspace' "$OPENCLAW_CONFIG" 2>/dev/null || true)
        TARGET_WORKSPACES="$TARGET_WORKSPACES $JSON_WS"
    else
        JSON_WS=$(grep '"workspace":' "$OPENCLAW_CONFIG" | sed 's/.*"workspace": "\(.*\)".*/\1/' || true)
        TARGET_WORKSPACES="$TARGET_WORKSPACES $JSON_WS"
    fi
fi

# 来源 3: 启发式扫描 (查找包含 SOUL.md 的 workspace-* 目录)
if [ -d "$WORKSPACE_BASE" ]; then
    H_WS=$(find "$WORKSPACE_BASE" -maxdepth 2 -type f -name "SOUL.md" | xargs -I {} dirname {} | grep "/workspace-" || true)
    TARGET_WORKSPACES="$TARGET_WORKSPACES $H_WS"
fi

# 默认包含主工作区 (如果存在)
[ -d "$WORKSPACE_BASE/workspace-main" ] && TARGET_WORKSPACES="$TARGET_WORKSPACES $WORKSPACE_BASE/workspace-main"

# 去重并验证目录是否存在
CLEAN_WS=""
for ws in $TARGET_WORKSPACES; do
    if [ -d "$ws" ]; then
        CLEAN_WS="$CLEAN_WS $ws"
    fi
done
TARGET_WORKSPACES=$(echo "$CLEAN_WS" | tr ' ' '\n' | sort -u | grep -v "^$" || true)

# 确认卸载
echo -e "${RED}警告: 这将停止所有相关服务并删除以下内容:${NC}"
for d in $CLEAN_DIRS; do
    echo -e " - $d (项目文件)"
done
for ws in $TARGET_WORKSPACES; do
    echo -e " - $ws (工作区)"
done
echo -e " - $HOME/.clawui (本项目专用数据库及运行时数据)"
[ -d "$HOME/.clawui_release" ] && echo -e " - ~/.clawui_release (旧版数据)"
echo ""

# 使用 /dev/tty 确保在管道模式下也能输入
read -p "您确定要卸载并删除本项目相关的数据吗? (y/N) " confirm < /dev/tty

if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "卸载已取消。"
    exit 0
fi

# 停止并移除服务
echo -e "\n${BLUE}步骤 1: 正在停止并移除系统服务...${NC}"
if [ "$OS_TYPE" = "Darwin" ]; then
    for S_PATH in $SERVICES; do
        echo "正在停止服务: $(basename "$S_PATH")"
        launchctl unload "$S_PATH" 2>/dev/null || true
        rm "$S_PATH"
    done
else
    for S_PATH in $SERVICES; do
        S_FILE=$(basename "$S_PATH")
        echo "正在停止服务: $S_FILE"
        systemctl --user stop "$S_FILE" 2>/dev/null || true
        systemctl --user disable "$S_FILE" 2>/dev/null || true
        rm "$S_PATH"
    done
    systemctl --user daemon-reload
fi

# 移除数据和日志
echo -e "\n${BLUE}步骤 2: 正在清理本项目相关的数据和设置...${NC}"
# 清除探测到的工作区
for ws in $TARGET_WORKSPACES; do
    if [ -d "$ws" ]; then
        rm -rf "$ws"
        echo "已删除工作区: $ws"
    fi
done

rm -rf "$HOME/.clawui"
rm -rf "$HOME/.clawui_release"
[ -d "$HOME/.clawui_dev" ] && rm -rf "$HOME/.clawui_dev"

# Remove macOS log files
rm -f /tmp/clawui-*.log /tmp/clawui-*-err.log 2>/dev/null || true

echo "已清理本项目相关的配置和数据库数据。"

# 移除项目文件
echo -e "\n${BLUE}步骤 3: 正在移除项目文件...${NC}"
for d in $CLEAN_DIRS; do
    if [ -d "$d" ]; then
        rm -rf "$d"
        echo "已删除项目目录: $d"
    fi
done

echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}   卸载完成！                                   ${NC}"
echo -e "${GREEN}================================================${NC}"