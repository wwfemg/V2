#!/bin/bash

# 检查是否为root用户
if [ "$(id -u)" != "0" ]; then
    echo "此脚本必须以root权限运行" 1>&2
    exit 1
fi

STATUS_FILE="/tmp/install_status.txt"
rm -f $STATUS_FILE

echo "###########################################"
echo "# Naiveproxy与X-ui共存Caddy自动证书续签  #"
echo "###########################################"

while true; do
    read -p "准备好安装请按y，否则按q退出: " choice
    case $choice in
        [Yy]* ) break;;
        [Qq]* ) exit;;
        * ) echo "请输入y或q。";;
    esac
done

error_exit() {
    echo "错误发生，尝试自动修正..."
    "$@"
}

check_step_done() {
    grep -q "$1" $STATUS_FILE
}

mark_step_done() {
    echo "$1" >> $STATUS_FILE
}

if ! check_step_done "update_and_install"; then
    apt update -y || error_exit apt update -y
    apt install -y curl wget socat || error_exit apt install -y curl wget socat
    mark_step_done "update_and_install"
fi

if ! check_step_done "setup_bbr"; then
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf || error_exit echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf || error_exit echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p || error_exit sysctl -p
    lsmod | grep bbr || error_exit lsmod | grep bbr
    mark_step_done "setup_bbr"
fi

if ! check_step_done "install_xui"; then
    bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh) || error_exit bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)
    mark_step_done "install_xui"
fi

if ! check_step_done "install_caddy"; then
    apt install -y vim curl debian-keyring debian-archive-keyring apt-transport-https || error_exit apt install -y vim curl debian-keyring debian-archive-keyring apt-transport-https
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg || error_exit curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list || error_exit curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
    apt update -y || error_exit apt update -y
    apt install -y caddy || error_exit apt install -y caddy
    mark_step_done "install_caddy"
fi

if ! check_step_done "change_caddyfile"; then
    cd /etc/caddy/ || error_exit cd /etc/caddy/
    sed -i 's/8080/8400/g' Caddyfile || error_exit sed -i 's/8080/8400/g' Caddyfile
    sed -i 's/# //g' Caddyfile || error_exit sed -i 's/# //g' Caddyfile
    systemctl reload caddy || error_exit systemctl reload caddy
    mark_step_done "change_caddyfile"
fi

if ! check_step_done "install_go"; then
    apt install -y golang-go || error_exit apt install -y golang-go
    apt remove -y golang-go || error_exit apt remove -y golang-go
    if [ "$(uname -m)" == "x86_64" ]; then
      wget https://go.dev/dl/go1.22.2.linux-amd64.tar.gz || error_exit wget https://go.dev/dl/go1.22.2.linux-amd64.tar.gz
      rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz || error_exit rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz
    else
      wget https://go.dev/dl/go1.22.2.linux-arm64.tar.gz || error_exit wget https://go.dev/dl/go1.22.2.linux-arm64.tar.gz
      rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.2.linux-arm64.tar.gz || error_exit rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.2.linux-arm64.tar.gz
    fi
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    source ~/.bashrc
    go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest || error_exit go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
    ~/go/bin/xcaddy build --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive || error_exit ~/go/bin/xcaddy build --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive
    mv caddy /usr/bin/ || error_exit mv caddy /usr/bin/
    mark_step_done "install_go"
fi

rm -f $STATUS_FILE

# 获取用户输入，并更新 Caddyfile
read -p "請輸入域名: " domain
read -p "請輸入用戶名: " username
read -s -p "請輸入密碼: " password
echo

cat <<EOF > /etc/caddy/Caddyfile
:443, $domain {
   route {
                forward_proxy {
                        basic_auth $username $password
                        hide_ip
                        hide_via
                        probe_resistance
                }
   reverse_proxy localhost:8400
 }
}
EOF

# 验证Caddyfile
caddy validate --config /etc/caddy/Caddyfile || error_exit caddy validate --config /etc/caddy/Caddyfile

# 重新启动Caddy服务
systemctl restart caddy || error_exit systemctl restart caddy

# 检查Caddy服务状态
systemctl status caddy.service || {
    echo "Caddy服务启动失败，尝试修正..."
    journalctl -xeu caddy.service > /tmp/caddy_error.log
    echo "错误日志保存在 /tmp/caddy_error.log"
    exit 1
}

echo "Caddy服务已成功启动。"
