#!/bin/bash
set -e

git config --global credential.helper store

echo "Requesting WebSocket tunnel..."
git pull --rebase origin master || true
git commit --allow-empty -m "WS_TUNNEL_REQUEST" && git push

echo "Waiting for WebSocket endpoint..."
while [ ! -f ws_endpoint.txt ]; do
  git pull --rebase origin master
  sleep 3
done
WS_EP=$(cat ws_endpoint.txt)
echo "WebSocket endpoint: $WS_EP"

WS_IP=$(echo $WS_EP | cut -d: -f1)
WS_PORT=$(echo $WS_EP | cut -d: -f2)

# Install websocat locally (in WSL)
if ! command -v websocat &>/dev/null; then
  echo "Installing websocat locally..."
  sudo apt update && sudo apt install -y curl
  curl -L -o websocat https://github.com/vi/websocat/releases/latest/download/websocat.x86_64-unknown-linux-musl
  chmod +x websocat
  sudo mv websocat /usr/local/bin/
fi

# Test WebSocket connectivity (optional)
echo "Testing WebSocket connection..."
echo "Hello from client" | timeout 10 websocat -1 ws://$WS_IP:$WS_PORT || true
echo "WebSocket test completed."

echo "WebSocket tunnel ready. You can now use websocat to forward any TCP traffic."
echo "Example to create a SOCKS5 proxy on localhost:1080 through the tunnel:"
echo "  websocat -b 0.0.0.0:1080 ws://$WS_IP:$WS_PORT &"
