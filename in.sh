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
    echo "错误发生：$1"
    exit 1
}

check_step_done() {
    grep -q "$1" $STATUS_FILE
}

mark_step_done() {
    echo "$1" >> $STATUS_FILE
}

if ! check_step_done "update_and_install"; then
    apt update -y || error_exit "更新包列表失败"
    apt install -y curl wget socat || error_exit "安装基础包失败"
    mark_step_done "update_and_install"
fi

if ! check_step_done "setup_bbr"; then
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf || error_exit "写入sysctl.conf失败"
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf || error_exit "写入sysctl.conf失败"
    sysctl -p || error_exit "应用sysctl配置失败"
    lsmod | grep bbr || error_exit "BBR模块加载失败"
    mark_step_done "setup_bbr"
fi

if ! check_step_done "install_xui"; then
    bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh) || error_exit "安装X-ui失败"
    mark_step_done "install_xui"
fi

if ! check_step_done "install_caddy"; then
    apt install -y vim curl debian-keyring debian-archive-keyring apt-transport-https || error_exit "安装Caddy依赖包失败"
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg || error_exit "获取Caddy GPG密钥失败"
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list || error_exit "添加Caddy源失败"
    apt update -y || error_exit "更新包列表失败"
    apt install -y caddy || error_exit "安装Caddy失败"
    mark_step_done "install_caddy"
fi

if ! check_step_done "change_caddyfile"; then
    cd /etc/caddy/ || error_exit "切换到Caddy配置目录失败"
    sed -i 's/8080/8400/g' Caddyfile || error_exit "修改Caddyfile失败"
    sed -i 's/# //g' Caddyfile || error_exit "修改Caddyfile失败"
    systemctl reload caddy || error_exit "重新加载Caddy失败"
    mark_step_done "change_caddyfile"
fi

# 获取用户输入，并更新 Caddyfile
read -p "请输入您的域名 (例如：example.com): " domain
read -p "请输入用于验证的电子邮件地址 (例如：yourname@example.com): " email

cat <<EOF > /etc/caddy/Caddyfile
$domain {
    encode zstd gzip
    file_server
    reverse_proxy 127.0.0.1:8400
    tls $email {
        protocols tls1.2 tls1.3
        curves x25519 p384 p521
    }
}
EOF

# 重启Caddy并检查是否成功
systemctl restart caddy || error_exit "重启Caddy失败"

echo "安装和配置完成。"
