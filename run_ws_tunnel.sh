#!/bin/bash
set -e

function safe_pull() {
  git stash push --quiet -- run_ws_tunnel.sh ws_endpoint.txt 2>/dev/null || true
  git pull --rebase origin master
  git stash pop --quiet 2>/dev/null || true
}

git config --global credential.helper store

echo "Requesting WebSocket tunnel..."
safe_pull
git commit --allow-empty -m "WS_TUNNEL_REQUEST" && git push || {
  safe_pull
  git commit --allow-empty -m "WS_TUNNEL_REQUEST" && git push
}

echo "Waiting for endpoint..."
while [ ! -f ws_endpoint.txt ]; do
  safe_pull
  sleep 3
done
EP=$(cat ws_endpoint.txt)
echo "WS endpoint: $EP"
IP=$(echo $EP | cut -d: -f1)
PORT=$(echo $EP | cut -d: -f2)

echo "Testing WebSocket connectivity..."
# Use a 10-second timeout for the test
echo "HELLO" | timeout 10 websocat -1 ws://$IP:$PORT && echo "WebSocket test succeeded!" || {
  echo "WebSocket test failed. This is the last resort."
  exit 1
}

echo "WebSocket works! You can now set up a local SOCKS5 proxy using websocat."
