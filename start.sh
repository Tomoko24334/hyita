#!/bin/bash

echo "Setting up WireGuard VPN server..."

# Создаем конфигурацию, если её нет
if [ ! -f /etc/wireguard/wg0.conf ]; then
    echo "Creating WireGuard configuration..."
    mkdir -p /etc/wireguard
    cd /etc/wireguard
    
    # Генерируем ключи
    umask 077
    wg genkey | tee privatekey | wg pubkey > publickey
    
    # Создаем базовый конфиг
    cat > wg0.conf << EOF
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = $(cat privatekey)

PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF
    
    echo "Configuration created at /etc/wireguard/wg0.conf"
    echo "Server public key: $(cat publickey)"
fi

# Включаем форвардинг
sysctl -w net.ipv4.ip_forward=1

# Запускаем WireGuard
echo "Starting WireGuard..."
wg-quick up wg0

# Показываем статус
wg show

echo "WireGuard VPN server is running!"
echo "Listen port: 51820/udp"

# Держим контейнер активным
tail -f /dev/null