#!/bin/bash

# 输出Logo

echo "###########################################"
echo "#   Naiveproxy与X-ui共存Caddy自動證書續簽    #"
echo "###########################################"

# 添加用户提示
while true; do
    read -p "準備好安装请按y，否則按q退出: " choice
    case $choice in
        [Yy]* ) break;;  # 如果用户输入 y 或 Y，跳出循环，继续执行脚本
        [Qq]* ) exit;;    # 如果用户输入 q 或 Q，退出脚本
        * ) echo "请输入y或q。";;  # 如果用户输入其他字符，显示错误消息并重新询问
    esac
done
# 更新和安裝必要軟體
apt update -y
apt install -y curl wget socat

# 設定BBR
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
lsmod | grep bbr

# 安裝x-ui
bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)

# 更新和安裝Caddy
apt update
apt install -y vim curl debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt update
apt install -y caddy

# 更改Caddyfile
cd /etc/caddy/
sed -i 's/8080/8400/g' Caddyfile
sed -i 's/# //g' Caddyfile

# 重新加載Caddy
systemctl reload caddy

# 其他步驟
apt install -y golang-go
apt remove -y golang-go

# 根據架構安裝Go
if [ "$(uname -m)" == "x86_64" ]; then
  wget https://go.dev/dl/go1.20.7.linux-amd64.tar.gz
  rm -rf /usr/local/go && tar -C /usr/local -xzf go1.20.7.linux-amd64.tar.gz
else
  wget https://go.dev/dl/go1.21.0.linux-arm64.tar.gz
  rm -rf /usr/local/go && tar -C /usr/local -xzf go1.21.0.linux-arm64.tar.gz
fi

export PATH=$PATH:/usr/local/go/bin
go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
~/go/bin/xcaddy build --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive
mv caddy /usr/bin/
