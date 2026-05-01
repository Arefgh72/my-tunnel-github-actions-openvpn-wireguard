#!/bin/bash
set -e

echo "Requesting tunnel..."
git commit --allow-empty -m "TUNNEL_REQUEST" && git push

echo "Waiting for runner endpoint..."
while [ ! -f runner_endpoint.txt ]; do
  git pull --rebase origin main
  sleep 3
done
RUNNER_EP=$(cat runner_endpoint.txt)
echo "Runner endpoint: $RUNNER_EP"

echo "Generating keys..."
wg genkey | tee client_private.key | wg pubkey > client_pub.key
cp client_pub.key client_pubkey.txt
git add client_pubkey.txt
git commit -m "CLIENT_PUBKEY" && git push

echo "Waiting for runner public key..."
while [ ! -f runner_pubkey.txt ]; do
  git pull --rebase origin main
  sleep 3
done
RUNNER_PUBKEY=$(cat runner_pubkey.txt)
echo "Runner pubkey: $RUNNER_PUBKEY"

echo "Sending UDP probes to runner..."
RUNNER_IP=$(echo $RUNNER_EP | cut -d: -f1)
RUNNER_PORT=$(echo $RUNNER_EP | cut -d: -f2)
for i in $(seq 1 10); do
  echo "probe" > /dev/udp/$RUNNER_IP/$RUNNER_PORT 2>/dev/null || true
  sleep 1
done

echo "Waiting for our external endpoint..."
while [ ! -f client_endpoint.txt ]; do
  git pull --rebase origin main
  sleep 3
done
CLIENT_EP=$(cat client_endpoint.txt)
echo "Our endpoint: $CLIENT_EP"

echo "Setting up WireGuard interface..."
sudo ip link add wg0 type wireguard 2>/dev/null || true
sudo ip addr add 10.0.0.2/30 dev wg0 2>/dev/null || true
sudo wg set wg0 private-key client_private.key peer $RUNNER_PUBKEY allowed-ips 10.0.0.1/32 endpoint $RUNNER_EP
sudo ip link set wg0 up
sudo ip route add 10.0.0.1/32 dev wg0 2>/dev/null || true

echo "Tunnel established! Try: ping 10.0.0.1"
