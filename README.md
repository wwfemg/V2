一、僅測試了Debian系統

1、請先安裝crul
apt install curl

2、自建一鍵代NaiveProxy與x-ui共存，執行以下代碼
curl -O https://raw.githubusercontent.com/wwfemg/V2/master/in.sh && chmod +x in.sh && ./in.sh

3、一定選擇y，並且填寫好x-ui的用戶名和密碼，端口請設定為8400

4、再次提醒輸入域名的時候，請輸入解析好的域名，以及Naiveprocy的客戶端使用者用戶名和密碼

5、reboot
