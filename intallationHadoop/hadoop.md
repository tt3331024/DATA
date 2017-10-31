
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

### 3-安裝 Oracle JDK

**使用root登入centos7-hd0**  
下載oracle JDK

	wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u151-b12/e758a0de34e24606bca991d704f6dcbf/jdk-8u151-linux-x64.rpm"

開始安裝JDK

	rpm -ivh jdk-8u151-linux-x64.rpm

設定環境變數

	nano /etc/environment
	 JAVA_HOME=/usr/java/jdk1.8.0_151
	source /etc/environment
	echo $JAVA_HOME

確認 java

	jps

在每一台VM上安裝oracle JDK

### 4-安裝 Hadoop

**使用root登入centos7-hd0**  
下載 Hadoop

	wget http://apache.stu.edu.tw/hadoop/common/hadoop-2.7.4/hadoop-2.7.4.tar.gz

解壓縮並安裝 Hadoop

	tar -xzv -f ~/hadoop-2.7.4.tar.gz -C /usr/local
	chown -R hadoop:hadoop /usr/local/hadoop-2.7.4

在每台 VM 上安裝 Hadoop

**使用 hadoop 身份登入 centos7-hd0**  
建立資料夾及進行組態設定

	mkdir /usr/local/hadoop-2.7.4/tmp
	cd /usr/local/hadoop-2.7.4/etc/hadoop/
	cp mapred-site.xml.template mapred-site.xml

在修改以下設定檔
	
	nano slaves
	nano core-site.xml
	nano hdfs-site.xml
	nano mapred-site.xml
	nano yarn-site.xml

在 centos7-hd0 壓縮設定檔後傳到另外三台

	cd /usr/local/hadoop-2.7.4/etc
	tar -cz -f hadoop.tar.gz hadoop
	scp hadoop.tar.gz hadoop@centos7-hd1:/tmp
	scp hadoop.tar.gz hadoop@centos7-hd2:/tmp
	scp hadoop.tar.gz hadoop@centos7-hd3:/tmp

到另外三台VM解開壓縮檔

	tar -xz -f /tmp/hadoop.tar.gz -C /usr/local/hadoop-2.7.4/etc/

回到centos7-hd0 更新 Hadoop 環境設定
	
	nano ~/.bashrc
	 export HADOOP_HOME=/usr/local/hadoop-2.7.4
	 export PATH=$PATH:$HADOOP_HOME/bin
	 export PATH=$PATH:$HADOOP_HOME/sbin
	 export HADOOP_MAPERD_HOME=$HADOOP_HOME
	 export HADOOP_COMMON_HOME=$HADOOP_HOME
	 export HADOOP_HDFS_HOME=$HADOOP_HOME
	 export YARN_HOME=$HADOOP_HOME
	 export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
	 export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib"
	 export JAVA_LIBRARY_PATH=$HADOOP_HOME/lib/native:$JAVA_LIBRARY_PATH

source 環境設定

	. ~/.bashrc


### 5-Firewall 設定

**以root身份登入開通四台主機的防火牆**  
添加可通過防火牆的ip位置

	firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.0.0/24" accept' --permanent
	firewall-cmd --reload

可從`/etc/firewalld/zones/public.xml`看到完整防火牆的資訊

### 6-啟動 Hadoop

**使用hadoop登入centos7-hd0**  
初始hdfs(第一次登入時要進行格式化)

	hdfs namenode -format

未來須重新format時，要先在master機及worker機中，刪除hadoop裡的tmp檔案後，再重新初始hdfs

	rm -R /usr/local/hadoop-2.7.4/tmp
	mkdir /usr/local/hadoop-2.7.4/tmp

啟動job historyserver

	mr-jobhistory-daemon.sh start historyserver

啟動hadoop(hdfs & yarn)

	start-all.sh

確認Hadoop是否成功啟動，分別在master機和worker機測試

	jps
	# master 會有以下服務：NameNode / SecondaryNameNode / ResourceManager / JobHistoryServer
	# worker 會有以下服務：DataNode / NodeManager

查看 hadoop 版本

	hadoop version

可在Browser輸入下列網址來看hdfs和yarn的狀態  
* Namenode  
  http://centos7-hd0:50070
* SecondaryNamenode
  http://centos7-hd0:50090
* Yarn
  http://centos7-hd0:8088
* Job Historyserver
  http://centos7-hd0:19888/jobhistory

停止 hadoop

	stop-all.sh