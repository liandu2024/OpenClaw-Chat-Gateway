#!/bin/bash
set -e

# Configuration
# If not in a project dir, default to ~/OpenClaw-Chat-Gateway
INSTALL_DIR="$HOME/OpenClaw-Chat-Gateway"

# Detect OS
OS_TYPE="$(uname -s)"

emit_phase() {
    echo "::clawui-update-phase::$1"
}

restore_deploy_lockfiles() {
    git restore -- package-lock.json backend/package-lock.json frontend/package-lock.json 2>/dev/null || true
}

if [ -f "deploy-release.sh" ]; then
    PROJECT_ROOT="$(pwd)"
elif [ -d "$INSTALL_DIR" ]; then
    PROJECT_ROOT="$INSTALL_DIR"
else
    echo "Error: Could not find OpenClaw Chat Gateway installation."
    echo "Checked: $(pwd) and $INSTALL_DIR"
    exit 1
fi

if [ "$OS_TYPE" = "Darwin" ]; then
    SERVICE_DIR="$HOME/Library/LaunchAgents"
else
    SERVICE_DIR="$HOME/.config/systemd/user"
fi

echo "================================================"
echo "   OpenClaw Chat Gateway - 更新脚本"
echo "================================================"

# 1. 从服务文件中探测现有端口
emit_phase "detect-service"
EXISTING_PORT=""

if [ "$OS_TYPE" = "Darwin" ]; then
    # macOS: look for launchd plist files
    SERVICES=$(ls $SERVICE_DIR/com.clawui-*.plist 2>/dev/null | sort -V || true)

    if [ -n "$SERVICES" ]; then
        FIRST_SERVICE=$(echo "$SERVICES" | head -n 1)
        EXISTING_PORT=$(basename "$FIRST_SERVICE" | sed 's/com\.clawui-\([0-9]*\)\.plist/\1/')
        echo "检测到正在运行的端口: $EXISTING_PORT"
    fi
else
    # Linux: look for systemd service files
    SERVICES=$(ls $SERVICE_DIR/clawui-*.service 2>/dev/null | sort -V || true)

    if [ -n "$SERVICES" ]; then
        FIRST_SERVICE=$(echo "$SERVICES" | head -n 1)
        EXISTING_PORT=$(basename "$FIRST_SERVICE" | sed 's/clawui-\([0-9]*\)\.service/\1/')
        echo "检测到正在运行的端口: $EXISTING_PORT"
    else
        # 检查旧版服务文件
        if [ -f "$SERVICE_DIR/clawui.service" ]; then
            EXISTING_PORT="3115"
            echo "检测到旧版安装 (端口 3115)"
        fi
    fi
fi

TARGET_PORT=${1:-$EXISTING_PORT}
TARGET_PORT=${TARGET_PORT:-3115}

emit_phase "git-pull"
echo "正在从 GitHub 更新代码，目录: $PROJECT_ROOT..."
cd "$PROJECT_ROOT"
restore_deploy_lockfiles
git pull

emit_phase "deploy-release"
echo "开始升级端口 $TARGET_PORT 的服务..."
./deploy-release.sh "$TARGET_PORT"

emit_phase "complete"
echo "================================================"
echo "升级完成！"
echo "您的配置和数据已保留。"
echo "================================================"