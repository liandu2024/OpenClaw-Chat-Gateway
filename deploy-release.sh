#!/bin/bash
set -e

# Configuration
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SERVICE_DIR="$HOME/.config/systemd/user"

# Default Port
CLAWUI_PORT=${1:-3115}
SERVICE_NAME="clawui-${CLAWUI_PORT}"

echo "Deploying OpenClaw Chat Gateway (Consolidated)..."
echo "Project Path:  $PROJECT_ROOT"
echo "Service Port:  $CLAWUI_PORT"
echo "Service Name:  $SERVICE_NAME"

echo "Installing dependencies..."
cd "$PROJECT_ROOT"
npm install
cd backend && npm install && cd ..
cd frontend && npm install && cd ..

echo "Building projects..."
npm run build

echo "Patching OpenClaw configuration for local backend connections..."
node backend/patch-config.js || echo "Warning: Failed to patch OpenClaw config automatically."

NODE_PATH=$(command -v node || true)
if [ -z "$NODE_PATH" ]; then
    echo "Error: Could not find node in PATH. Please install Node.js and try again."
    exit 1
fi

echo "Using node binary: $NODE_PATH"

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

# Update WorkingDirectory, Node path, Port, and Description in the service file
sed -i "s|WorkingDirectory=.*|WorkingDirectory=$PROJECT_ROOT/backend|" "$SERVICE_DIR/$SERVICE_NAME.service"
sed -i "s|ExecStart=.*|ExecStart=$NODE_PATH dist/index.js|" "$SERVICE_DIR/$SERVICE_NAME.service"
sed -i "s/Environment=PORT=.*/Environment=PORT=$CLAWUI_PORT/" "$SERVICE_DIR/$SERVICE_NAME.service"
sed -i "s/Description=.*/Description=ClawUI Service (Port $CLAWUI_PORT)/" "$SERVICE_DIR/$SERVICE_NAME.service"

echo "Reloading systemd daemon..."
systemctl --user daemon-reload

echo "Enabling and starting service $SERVICE_NAME..."
systemctl --user enable "$SERVICE_NAME.service"
systemctl --user restart "$SERVICE_NAME.service"

# Ensure services stay running after logout
echo "Enabling lingering for user $(whoami)..."
if command -v loginctl >/dev/null 2>&1; then
    sudo loginctl enable-linger $(whoami) || echo "Warning: Could not enable lingering. Manual action may be required: sudo loginctl enable-linger $(whoami)"
fi

# Get local IP address
LOCAL_IP=$(hostname -I | awk '{print $1}')
[ -z "$LOCAL_IP" ] && LOCAL_IP="localhost"

echo "------------------------------------------------"
echo "Deployment complete!"
echo "Local Access:   http://localhost:$CLAWUI_PORT"
echo "Network Access: http://$LOCAL_IP:$CLAWUI_PORT"
echo "------------------------------------------------"
echo "Check status with: systemctl --user status $SERVICE_NAME"
