#!/bin/bash
set -e

git config --global credential.helper store

# ---------- مرحلهٔ صفر: دریافت IP واقعی ما از سرور STUN داخلی ----------
echo "Requesting STUN server..."
git pull --rebase origin master || true
git commit --allow-empty -m "STUN_REQUEST" && git push

echo "Waiting for STUN server address..."
while [ ! -f stun_server.txt ]; do
  git pull --rebase origin master
  sleep 3
done
STUN_ADDR=$(cat stun_server.txt)
echo "STUN server at: $STUN_ADDR"

STUN_IP=$(echo $STUN_ADDR | cut -d: -f1)
STUN_PORT=$(echo $STUN_ADDR | cut -d: -f2)

echo "Sending probe to STUN server..."
python3 -c "import socket; sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); sock.sendto(b'probe', ('$STUN_IP', $STUN_PORT)); sock.close()"

echo "Waiting for our external address..."
while [ ! -f client_stun.txt ]; do
  git pull --rebase origin master
  sleep 3
done
CLIENT_EP=$(cat client_stun.txt)
echo "Our endpoint: $CLIENT_EP"

# ---------- مرحلهٔ اصلی: تونل وایرگارد ----------
echo "Requesting tunnel..."
git commit --allow-empty -m "TUNNEL_REQUEST" && git push

echo "Waiting for runner endpoint..."
while [ ! -f runner_endpoint.txt ]; do
  git pull --rebase origin master
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
  git pull --rebase origin master
  sleep 3
done
RUNNER_PUBKEY=$(cat runner_pubkey.txt)
echo "Runner pubkey: $RUNNER_PUBKEY"

echo "Setting up WireGuard interface..."
sudo ip link add wg0 type wireguard 2>/dev/null || true
sudo ip addr add 10.0.0.2/30 dev wg0 2>/dev/null || true
sudo wg set wg0 private-key client_private.key peer $RUNNER_PUBKEY allowed-ips 10.0.0.1/32 endpoint $RUNNER_EP
sudo ip link set wg0 up
sudo ip route add 10.0.0.1/32 dev wg0 2>/dev/null || true

echo "Tunnel established! Try: ping 10.0.0.1"
