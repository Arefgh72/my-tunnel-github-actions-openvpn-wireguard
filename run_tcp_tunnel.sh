#!/bin/bash
set -e

# تابع کمکی برای pull ایمن
function safe_pull() {
  git stash push --quiet -- run_tcp_tunnel.sh socks_endpoint.txt 2>/dev/null || true
  git pull --rebase origin master
  git stash pop --quiet 2>/dev/null || true
}

git config --global credential.helper store

echo "Requesting TCP tunnel..."
safe_pull
git commit --allow-empty -m "SOCKS_TCP_REQUEST" && git push || {
  # اگر push رد شد، به معنی کامیت جدید در remote است
  safe_pull
  git commit --allow-empty -m "SOCKS_TCP_REQUEST" && git push
}

echo "Waiting for endpoint..."
while [ ! -f socks_endpoint.txt ]; do
  safe_pull
  sleep 3
done
EP=$(cat socks_endpoint.txt)
echo "Endpoint: $EP"
IP=$(echo $EP | cut -d: -f1)
PORT=$(echo $EP | cut -d: -f2)

echo "Testing raw TCP connectivity..."
echo "HELLO" | timeout 5 socat - TCP:$IP:$PORT && {
  echo "TCP test succeeded! We can now set up a proper SOCKS5 tunnel."
} || {
  echo "TCP test failed. It is very likely blocked."
  exit 1
}
