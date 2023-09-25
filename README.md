一、安裝

僅測試了Debian系統

1、請先安裝crul
apt install curl

2、自建一鍵代NaiveProxy與x-ui共存，執行以下代碼
curl -O https://raw.githubusercontent.com/wwfemg/V2/master/in.sh && chmod +x in.sh && ./in.sh

3、一定選擇y，並且填寫好x-ui的用戶名和密碼，端口請設定為8400

4、再次提醒輸入域名的時候，請輸入解析好的域名，以及Naiveprocy的客戶端使用者用戶名和密碼

5、reboot

二、使用域名證書路徑

1、x-ui使用的時候，如果需要域名證書，請在以下路徑尋找
/var/lib/caddy/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/域名/域名證書

2、Naiveprocy客戶端使用的時候 用戶名和密碼就是最後輸入域名後讓輸入的用戶名和密碼。端口號為：443

