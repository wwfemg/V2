
NaiveProxy

1、apt update
2、apt install vim
3、apt install -y debian-keyring debian-archive-keyring apt-transport-https
4、curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
5、curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
6、apt update
7、apt install caddy
9、進入：cd /etc/caddy/
10、編輯：vim Caddyfile   

更換端口為x-ui面板端口和去掉#

11、systemctl reload caddy
12、apt  install golang-go
13、apt remove golang-go
14、wget https://go.dev/dl/go1.19.4.linux-amd64.tar.gz
15、rm -rf /usr/local/go && tar -C /usr/local -xzf go1.19.4.linux-amd64.tar.gz
16、export PATH=$PATH:/usr/local/go/bin
17、go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
18、~/go/bin/xcaddy build --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive
19、輸入ls 看到caddy
20、mv caddy /usr/bin/
21、vim /etc/caddy/Caddyfile
22、改配置文件
