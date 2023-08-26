#!/bin/bash

# 函數用於重試失敗的命令
retry_command() {
  for i in {1..5}; do
    "$@" && return 0
    echo "Command failed. Retrying in 5 seconds..."
    sleep 5
  done
  echo "Command failed after 5 attempts. Exiting."
  exit 1
}

# 更新和安裝必要軟體
retry_command apt update -y
retry_command apt install -y curl wget socat

# 設定BBR
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
retry_command sysctl -p
retry_command lsmod | grep bbr

# 安裝x-ui，並自動輸入用戶名、密碼和端口
echo -e "naive\nnaive\n8400" | retry_command bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)

# 更新和安裝Caddy
retry_command apt update
retry_command apt install -y vim curl debian-keyring debian-archive-keyring apt-transport-https
retry_command curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
retry_command curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
retry_command apt update
retry_command apt install -y caddy

# 更改Caddyfile
cd /etc/caddy/
sed -i 's/8080/8400/g' Caddyfile
sed -i 's/# //g' Caddyfile

# 重新加載Caddy
retry_command systemctl reload caddy

# 其他步驟
retry_command apt install -y golang-go
retry_command apt remove -y golang-go

# 根據架構安裝Go
if [ "$(uname -m)" == "x86_64" ]; then
  retry_command wget https://go.dev/dl/go1.20.7.linux-amd64.tar.gz
  retry_command rm -rf /usr/local/go && tar -C /usr/local -xzf go1.20.7.linux-amd64.tar.gz
else
  retry_command wget https://go.dev/dl/go1.21.0.linux-arm64.tar.gz
  retry_command rm -rf /usr/local/go && tar -C /usr/local -xzf go1.21.0.linux-arm64.tar.gz
fi

export PATH=$PATH:/usr/local/go/bin
retry_command go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
retry_command ~/go/bin/xcaddy build --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive
retry_command mv caddy /usr/bin/
