#!/bin/bash

# 初始化一个状态文件
STATUS_FILE="/tmp/install_status.txt"

# 输出Logo
echo "###########################################"
echo "# Naiveproxy与X-ui共存Caddy自动证书续签  #"
echo "###########################################"

# 添加用户提示
while true; do
    read -p "准备好安装请按y，否则按q退出: " choice
    case $choice in
        [Yy]* ) break;;
        [Qq]* ) exit;;
        * ) echo "请输入y或q。";;
    esac
done

# 出错时的操作
error_exit() {
    echo "错误发生，选择重新执行或退出（r/e）: "
    read choice
    case $choice in
        [Rr]*) ;;
        [Ee]*) exit 1;;
        *) echo "无效选项，退出"; exit 1;;
    esac
}

# 检查步骤完成
check_step_done() {
    grep -q "$1" $STATUS_FILE
}

# 标记步骤完成
mark_step_done() {
    echo "$1" >> $STATUS_FILE
}

# 更新和安装必要软件
if ! check_step_done "update_and_install"; then
    apt update -y || error_exit
    apt install -y curl wget socat || error_exit
    mark_step_done "update_and_install"
fi

# 设置BBR
if ! check_step_done "setup_bbr"; then
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf || error_exit
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf || error_exit
    sysctl -p || error_exit
    lsmod | grep bbr || error_exit
    mark_step_done "setup_bbr"
fi

# 安装x-ui
if ! check_step_done "install_xui"; then
    bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh) || error_exit
    mark_step_done "install_xui"
fi

# 更新和安装Caddy
if ! check_step_done "install_caddy"; then
    apt update || error_exit
    apt install -y vim curl debian-keyring debian-archive-keyring apt-transport-https || error_exit
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg || error_exit
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list || error_exit
    apt update || error_exit
    apt install -y caddy || error_exit
    mark_step_done "install_caddy"
fi

# 更改Caddyfile
if ! check_step_done "change_caddyfile"; then
    cd /etc/caddy/ || error_exit
    sed -i 's/8080/8400/g' Caddyfile || error_exit
    sed -i 's/# //g' Caddyfile || error_exit
    systemctl reload caddy || error_exit
    mark_step_done "change_caddyfile"
fi

# 其他步骤和安装Go
if ! check_step_done "install_go"; then
    apt install -y golang-go || error_exit
    apt remove -y golang-go || error_exit
    if [ "$(uname -m)" == "x86_64" ]; then
      wget https://go.dev/dl/go1.20.7.linux-amd64.tar.gz || error_exit
      rm -rf /usr/local/go && tar -C /usr/local -xzf go1.20.7.linux-amd64.tar.gz || error_exit
    else
      wget https://go.dev/dl/go1.21.0.linux-arm64.tar.gz || error_exit
      rm -rf /usr/local/go && tar -C /usr/local -xzf go1.21.0.linux-arm64.tar.gz || error_exit
    fi
    export PATH=$PATH:/usr/local/go/bin
    go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest || error_exit
    ~/go/bin/xcaddy build --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive || error_exit
    mv caddy /usr/bin/ || error_exit
    mark_step_done "install_go"
fi

# 全部成功，重置状态文件
echo "" > $STATUS_FILE

# 打开vim编辑器以编辑/etc/caddy/Caddyfile文件
vim /etc/caddy/Caddyfile


# 保存并退出，然后重启Caddy服务
systemctl restart caddy
