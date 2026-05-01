#!/bin/bash
set -e
git config --global credential.helper store

echo "Requesting TCP tunnel..."
git pull --rebase origin master || true
git commit --allow-empty -m "SOCKS_TCP_REQUEST" && git push

echo "Waiting for endpoint..."
while [ ! -f socks_endpoint.txt ]; do
  git pull --rebase origin master
  sleep 3
done
EP=$(cat socks_endpoint.txt)
echo "Endpoint: $EP"
IP=$(echo $EP | cut -d: -f1)
PORT=$(echo $EP | cut -d: -f2)

echo "Testing raw TCP connectivity..."
echo "HELLO" | timeout 5 socat - TCP:$IP:$PORT || {
  echo "TCP test failed. It is likely blocked."
  exit 1
}
echo "TCP test succeeded! We can now set up a proper SOCKS5 tunnel."
# If we reach here, TCP works.
