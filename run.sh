#!/bin/bash
set -e

git config --global credential.helper store

echo "Requesting tunnel..."
git pull --rebase origin master || true
git commit --allow-empty -m "TUNNEL_REQUEST" && git push

echo "Waiting for runner info..."
while [ ! -f runner_endpoint.txt ]; do
  git pull --rebase origin master
  sleep 3
done
RUNNER_EP=$(cat runner_endpoint.txt)
echo "Runner endpoint: $RUNNER_EP"

while [ ! -f runner_pubkey.txt ]; do
  git pull --rebase origin master
  sleep 3
done
RUNNER_PUBKEY=$(cat runner_pubkey.txt)
echo "Runner pubkey: $RUNNER_PUBKEY"

echo "Generating keys and sending public key..."
wg genkey | tee client_private.key | wg pubkey > client_pub.key
cp client_pub.key client_pubkey.txt
git add client_pubkey.txt
git commit -m "CLIENT_PUBKEY" && git push

echo "Setting up interface and sending WireGuard handshake..."
sudo ip link add wg0 type wireguard 2>/dev/null || true
sudo ip addr add 10.0.0.2/30 dev wg0 2>/dev/null || true
sudo wg set wg0 private-key client_private.key peer $RUNNER_PUBKEY allowed-ips 10.0.0.1/32 endpoint $RUNNER_EP
sudo ip link set wg0 up

echo "Waiting for runner to publish our real endpoint..."
while [ ! -f client_endpoint.txt ]; do
  git pull --rebase origin master
  sleep 3
done
CLIENT_EP=$(cat client_endpoint.txt)
echo "Our endpoint: $CLIENT_EP"

# Update WireGuard with real endpoint just in case (already set by runner)
sudo wg set wg0 peer $RUNNER_PUBKEY endpoint $CLIENT_EP 2>/dev/null || true
sudo ip route add 10.0.0.1/32 dev wg0 2>/dev/null || true

echo "Tunnel established! Try: ping 10.0.0.1"
