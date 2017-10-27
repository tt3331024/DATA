
### 1-設定 Server 
- 安裝四台VM，機器名稱分別取為 centos7-hd0 / centos7-hd1 / centos7-hd2 / centos7-hd3
- 硬體規格：Memory=2GB / Processors=1 / Disk=60GB / Network Adapter=Bridge
- 開始安裝CentOS，選取Infrastructure Server(基礎架構伺服器)

### 2-設定 SSH

開機使用root登入cnetos7-hd0

增加ip位置和hosts name
	nano /etc/hosts
		192.168.0.100 centos7-hd0
		192.168.0.101 centos7-hd1
		192.168.0.102 centos7-hd2
		192.168.0.103 centos7-hd3

四台機器間互ping確認互通
	ping centos7-hd0 -c 4
	ping centos7-hd1 -c 4
	ping centos7-hd2 -c 4
	ping centos7-hd3 -c 4

修改SSH設定
	nano /etc/ssh/sshd_config
		Protocol 2 # 限定只能用 version 2 連線
		PermitRootLogin no # 不充許遠端使用 root 登入

修改可使用連線 SSH 設定
	nano /etc/hosts.allow
		sshd: 192.168.0.*: allow

修改其它電腦不可連線 SSH 設定
	nano /etc/hosts.deny
		sshd: ALL

重新啟動SSH關閉或開啟語法如下
	service sshd restart
	service sshd stop
	service sshd start

增加hadoop帳號
	useradd hadoop 
	passwd hadoop

**離開root帳號**
**用hadoop帳號登入**

在centos7-hd0設定SSH無密碼登入
	ssh-keygen -t rsa
	# 金鑰放置位置使用預設，直接return即可
	# passphrase不用設定，一樣直接return即可

將公鑰複製到authorized_keys並修改權限
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

### 3-安裝 Oracle JDK

**使用root登入centos7-hd0**  
下載oracle JDK
	wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u151-b12/e758a0de34e24606bca991d704f6dcbf/jdk-8u151-linux-x64.rpm"

開始安裝JDK
	rpm -ivh jdk-8u121-linux-x64.rpm

設定環境變數
	nano /etc/environment
		JAVA_HOME=/usr/java/jdk1.8.0_121
	source /etc/environment
	echo $JAVA_HOME

確認 java
	jps

在每一台VM上安裝oracle JDK