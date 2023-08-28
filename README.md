自建一鍵代NaiveProxy與x-ui共存
curl -O https://raw.githubusercontent.com/wwfemg/V2/master/in.sh && chmod +x in.sh && ./in.sh
請輸入這條命令完成

1、系統會自動安裝x-ui，並手動確定用戶名和密碼以及端口 端口就設定為8400
2、請注意修改caddyfile文件中的x-ui端口為8400
3、中途caddy報錯是因為沒有配置域名，請忽略，按r繼續
4、最後完成編譯之後，系統會自動進入編輯caddyfile文件，請按i進入編輯模式
5、配置文件，請根據自己需求填寫如下：
:443, 域名 {
	  route {
                forward_proxy {
                        basic_auth 用戶名 密碼
                        hide_ip
                        hide_via
                        probe_resistance
                }
	  reverse_proxy localhost:8400
	}
}
