#!/bin/bash
set -e

# Configuration
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SKIP_SERVICE_RESTART=${CLAWUI_SKIP_SERVICE_RESTART:-0}
BROWSER_WARMUP_MARKER="$HOME/${CLAWUI_DATA_DIR:-.clawui}/browser-warmup.pending"

# Detect OS
OS_TYPE="$(uname -s)"

# Set service directories based on OS
if [ "$OS_TYPE" = "Darwin" ]; then
    SERVICE_DIR="$HOME/Library/LaunchAgents"
    SERVICE_EXT="plist"
else
    SERVICE_DIR="$HOME/.config/systemd/user"
    SERVICE_EXT="service"
fi

export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# Cross-platform sed in-place: macOS BSD sed requires backup suffix, GNU sed does not
sed_inplace() {
    if [ "$OS_TYPE" = "Darwin" ]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# Cross-platform get local IP
get_local_ip() {
    if [ "$OS_TYPE" = "Darwin" ]; then
        ipconfig getifaddr en0 2>/dev/null || echo ""
    else
        hostname -I 2>/dev/null | awk '{print $1}' || echo ""
    fi
}

emit_phase() {
    echo "::clawui-update-phase::$1"
}

restore_deploy_lockfiles() {
    git restore -- package-lock.json backend/package-lock.json frontend/package-lock.json 2>/dev/null || true
}

# Default Port
CLAWUI_PORT=${1:-3115}
SERVICE_NAME="clawui-${CLAWUI_PORT}"

# Build steps need devDependencies even when the service environment sets NODE_ENV=production.
export NPM_CONFIG_PRODUCTION=false
export npm_config_production=false
export NPM_CONFIG_INCLUDE=dev
export npm_config_include=dev

emit_phase "install-dependencies"
echo "Deploying OpenClaw Chat Gateway (Consolidated)..."
echo "Project Path:  $PROJECT_ROOT"
echo "Service Port:  $CLAWUI_PORT"
echo "Service Name:  $SERVICE_NAME"
echo "OS Type:       $OS_TYPE"

echo "Installing dependencies..."
cd "$PROJECT_ROOT"
npm install --include=dev
cd backend && npm install --include=dev && cd ..
cd frontend && npm install --include=dev && cd ..

emit_phase "build"
echo "Building projects..."
npm run build
restore_deploy_lockfiles

emit_phase "patch-config"
echo "Patching OpenClaw configuration for local backend connections..."
node backend/patch-config.js || echo "Warning: Failed to patch OpenClaw config automatically."

emit_phase "setup-service"
if [ "$OS_TYPE" = "Darwin" ]; then
    # ── macOS: launchd setup ──
    echo "Setting up launchd service (macOS)..."

    PLIST_FILE="$SERVICE_DIR/com.$SERVICE_NAME.plist"

    # Stop and unload existing service if present
    if [ -f "$PLIST_FILE" ]; then
        echo "Unloading existing service..."
        launchctl unload "$PLIST_FILE" 2>/dev/null || true
    fi

    # Find Node.js path
    NODE_BIN="$(command -v node)"
    if [ -z "$NODE_BIN" ]; then
        echo "Error: Could not find node in PATH."
        exit 1
    fi

    # Generate plist from template
    mkdir -p "$SERVICE_DIR"
    cp "$PROJECT_ROOT/clawui.plist.template" "$PLIST_FILE"

    sed_inplace "s|CLAWUI_LABEL|com.$SERVICE_NAME|g" "$PLIST_FILE"
    sed_inplace "s|CLAWUI_PORT|$CLAWUI_PORT|g" "$PLIST_FILE"
    sed_inplace "s|CLAWUI_WORKDIR|$PROJECT_ROOT|g" "$PLIST_FILE"
    sed_inplace "s|NODE_PATH|$NODE_BIN|g" "$PLIST_FILE"

    echo "Loading launchd service..."
    launchctl load "$PLIST_FILE"

else
    # ── Linux: systemd setup ──
    echo "Setting up systemd service..."
    mkdir -p "$SERVICE_DIR"

    # Clean up old services if they exist (legacy single service name)
    if [ "$CLAWUI_PORT" == "3115" ] && [ -f "$SERVICE_DIR/clawui.service" ]; then
        echo "Transitioning from legacy clawui.service to $SERVICE_NAME.service..."
        systemctl --user stop clawui.service 2>/dev/null || true
        systemctl --user disable clawui.service 2>/dev/null || true
        rm -f "$SERVICE_DIR/clawui.service"
    fi

    # Copy and update the consolidated service file
    cp "$PROJECT_ROOT/clawui.service" "$SERVICE_DIR/$SERVICE_NAME.service"

    # Update WorkingDirectory, Port, and Description in the service file
    sed_inplace "s|WorkingDirectory=.*|WorkingDirectory=$PROJECT_ROOT/backend|" "$SERVICE_DIR/$SERVICE_NAME.service"
    sed_inplace "s/Environment=PORT=.*/Environment=PORT=$CLAWUI_PORT/" "$SERVICE_DIR/$SERVICE_NAME.service"
    sed_inplace "s/Description=.*/Description=ClawUI Service (Port $CLAWUI_PORT)/" "$SERVICE_DIR/$SERVICE_NAME.service"
    if grep -q '^Environment=PATH=' "$SERVICE_DIR/$SERVICE_NAME.service"; then
        sed_inplace "s|^Environment=PATH=.*|Environment=PATH=$HOME/.npm-global/bin:$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin|" "$SERVICE_DIR/$SERVICE_NAME.service"
    else
        sed_inplace "/Environment=NODE_ENV=.*/a Environment=PATH=$HOME/.npm-global/bin:$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" "$SERVICE_DIR/$SERVICE_NAME.service"
    fi

    echo "Reloading systemd daemon..."
    systemctl --user daemon-reload

    echo "Enabling service $SERVICE_NAME..."
    systemctl --user enable "$SERVICE_NAME.service"
fi

if [ "$SKIP_SERVICE_RESTART" = "1" ]; then
    echo "Skipping service restart because CLAWUI_SKIP_SERVICE_RESTART=1"
else
    emit_phase "restart-openclaw-runtime"
    echo "Restarting OpenClaw gateway..."
    if command -v openclaw >/dev/null 2>&1; then
        openclaw gateway restart --json || openclaw gateway restart || echo "Warning: Failed to restart OpenClaw gateway automatically."
    else
        echo "Warning: openclaw command not found in PATH; skipped gateway restart."
    fi

    emit_phase "service-restart"
    echo "Restarting service $SERVICE_NAME..."
    mkdir -p "$(dirname "$BROWSER_WARMUP_MARKER")"
    touch "$BROWSER_WARMUP_MARKER"

    if [ "$OS_TYPE" = "Darwin" ]; then
        launchctl unload "$SERVICE_DIR/com.$SERVICE_NAME.plist" 2>/dev/null || true
        launchctl load "$SERVICE_DIR/com.$SERVICE_NAME.plist"
    else
        systemctl --user restart "$SERVICE_NAME.service"
    fi
fi

# Ensure services stay running after logout (Linux only)
if [ "$OS_TYPE" != "Darwin" ]; then
    echo "Enabling lingering for user $(whoami)..."
    if command -v loginctl >/dev/null 2>&1; then
        sudo -n loginctl enable-linger $(whoami) || echo "Warning: Could not enable lingering. Manual action may be required: sudo loginctl enable-linger $(whoami)"
    fi
fi

# Get local IP address
LOCAL_IP=$(get_local_ip)
[ -z "$LOCAL_IP" ] && LOCAL_IP="localhost"

echo "------------------------------------------------"
echo "Deployment complete!"
echo "Local Access:   http://localhost:$CLAWUI_PORT"
echo "Network Access: http://$LOCAL_IP:$CLAWUI_PORT"
echo "------------------------------------------------"
if [ "$OS_TYPE" = "Darwin" ]; then
    echo "Check status with: launchctl list | grep $SERVICE_NAME"
    echo "View logs with:    cat /tmp/clawui-$CLAWUI_PORT.log"
    echo "Stop service:      launchctl unload ~/Library/LaunchAgents/com.$SERVICE_NAME.plist"
else
    echo "Check status with: systemctl --user status $SERVICE_NAME"
fi