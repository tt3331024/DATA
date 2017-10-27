
### 1-設定 Server 
- 安裝四台VM，機器名稱分別取為 centos7-hd0 / centos7-hd1 / centos7-hd2 / centos7-hd3
- 硬體規格：Memory=2GB / Processors=1 / Disk=60GB / Network Adapter=Bridge
- 開始安裝CentOS，選取Infrastructure Server(基礎架構伺服器)

### 2-設定 SSH

開機使用 root 登入 cnetos7-hd0
拿掉 IPv6 設定及取消 localhost 127.0.0.1 及 127.0.1.1 對應

	nano /etc/hosts
		192.168.0.100 centos7-hd0
		192.168.0.101 centos7-hd1
		192.168.0.102 centos7-hd2
		192.168.0.103 centos7-hd3

增加以下三行關閉 IPv6
nano /etc/sysctl.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
# 檢查設定是否生效
sysctl -p

四台機器間互ping確認互通
	ping centos7-hd0 -c 4
	ping centos7-hd1 -c 4
	ping centos7-hd2 -c 4
	ping centos7-hd3 -c 4

修改 SSH 設定
	nano /etc/ssh/sshd_config
		Protocol 2 # 限定只能用 version 2 連線
		PermitRootLogin no # 不充許遠端使用 root 登入

修改可使用連線 SSH 設定
	nano /etc/hosts.allow
		sshd: 192.168.0.*: allow

修改其它電腦不可連線 SSH 設定
	nano /etc/hosts.deny
		sshd: ALL

重新啟動 SSH 關閉或開啟語法如下
	service sshd restart
	service sshd stop
	service sshd start

增加 hadoop 帳號
	useradd hadoop 
	passwd hadoop

**離開 root 帳號**
**用 hadoop 帳號登入**

在 centos7-hd0 設定 SSH
	ssh-keygen -t rsa
	# 金鑰放置位置使用預設，直接return即可
	# passphrase不用設定，一樣直接return即可

將公鑰複製到authorized_keys 並修改權限
	cat ~/.ssh/id_rsa.pub >> .ssh/authorized_keys
	chmod 644 ~/.ssh/authorized_keys


**使用hadoop的身分在 centos7-hd1 / centos7-hd2 / centos7-hd3 創立 ssh 資料夾**
	mkdir ~/.ssh
	chmod 700 ~/.ssh

回到centos7-hd0，將authorized_keys 傳送到另外三台主機

	scp ~/.ssh/authorized_keys hadoop@centos7-hd1:/home/hadoop/.ssh/
	scp ~/.ssh/authorized_keys hadoop@centos7-hd2:/home/hadoop/.ssh/
	scp ~/.ssh/authorized_keys hadoop@centos7-hd3:/home/hadoop/.ssh/


務必確認每台主機中的**.ssh 資料夾的權限一定要為700**, **authorized_keys 的權限要為644**
	chmod 700 ~/hadoop/.ssh/
	chmod 644 ~/hadoop/.ssh/authorized_keys

測試從 hd0 是否可用ssh進行無密碼登入每一台 Hadoop 主機(包含自己 hd0)
	ssh centos7-hd0
	ssh centos7-hd1
	ssh centos7-hd2
	ssh centos7-hd3
	exit

# ----- 3-安裝 Oracle JDK -----------------------------------------------------------------------------
