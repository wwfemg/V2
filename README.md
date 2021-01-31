# V2Ray


從這裡開啟你的新秘籍！
江湖有很多傳說，也有人樂此不疲尋找更多的武功秘籍。我整理這個部分，僅供參考！

第一部：服務器，建議：CentOS 7 ，安裝curl ：

ubuntu/debian 系统安装 Curl 方法:

apt-get update -y && apt-get install curl -y

centos 系统安装 Curl 方法:

yum update -y && yum install curl -y && yum -y install wget

第二部：安裝加速，建議BBRPlus：

wget --no-check-certificate -O tcp.sh https://github.com/wwfemg/Linux-NetSpeed/raw/master/tcp.sh && chmod +x tcp.sh && ./tcp.sh

第三部：安裝V2Ray

如果需要安裝寶塔，請加速完先安裝。不需要，跳過看下一步：

寶塔：

yum install -y wget && wget -O install.sh http://download.bt.cn/install/install_6.0.sh && sh install.sh


V2Ray：

bash <(curl -Ls https://blog.sprov.xyz/v2-ui.sh)

記得在寶塔裡面放行端口：切記

