# ----- 1-設定 Server ---------------------------------------------------------------------------------

# 安裝 VM CentOS-7 ，機器名稱為： centos7-maria10
# 硬體規格：Disk=60G Processors=1 RAM=2GB Network=Bridge ID/PWD=root/********
# 開始安裝CentOS，選取Infrastructure Server(基礎架構伺服器)


# ----- 2-設定 SSH ------------------------------------------------------------------------------------

# 開機使用 root 登入
# 拿掉 IPv6 設定及取消 localhost 127.0.0.1 及 127.0.1.1 對應
nano /etc/hosts
192.168.0.110 centos7-maria10

# 增加以下三行關閉 IPv6
nano /etc/sysctl.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
# 檢查設定是否生效
sysctl -p

# 修改 SSH 設定
nano /etc/ssh/sshd_config
Protocol 2 # 限定只能用 version 2 連線
PermitRootLogin no # 不充許遠端使用 root 登入

# 修改可使用連線 SSH 設定
nano /etc/hosts.allow
sshd: 192.168.0.*: allow
mysqld: 192.168.0.*: allow

# 修改其它電腦不可連線 SSH 設定
nano /etc/hosts.deny
sshd: ALL
mysqld: ALL

# 重新啟動 SSH 關閉或開啟語法如下
service sshd restart
service sshd stop
service sshd start


# ----- 3-安裝 MariaDB --------------------------------------------------------------------------------

# 修改 repository 設定
nano /etc/yum.repos.d/MariaDB.repo

# 輸入以下內容
# MariaDB 10.0 CentOS repository list
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.0/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1

# 安裝 MariaDB
yum install MariaDB-server MariaDB-client

# 修改編碼及緩衝
nano /etc/my.cnf
# 在最末端輸入下列內容
[mysqld]
collation-server = utf8_unicode_ci
character-set-server = utf8
init-connect = 'SET NAMES utf8'
max_allowed_packet=1024M

# 啟動服務
/etc/init.d/mysql start

# format database
mysql_secure_installation

Set root password? [Y/n] Y
# 輸入新的 root 密碼並再做一次確認
Remove anonymous users? [Y/n] Y
Disallow root login remotely? [Y/n] Y
Remove test database and access to it? [Y/n] Y
Reload privilege tables now? [Y/n] Y

# 重啟服務
/etc/init.d/mysql restart

# 確認服務狀態
netstat -tln
# 在 Local Address 中有看到 3306 就是有啟動 mariaDB

# 關閉服務
/etc/init.d/mysql stop

# 設定權限
chown -R mysql:mysql /var/lib/mysql

# 防火牆設定（開放 3306）
firewall-cmd --list-all
firewall-cmd --add-port=3306/tcp 
firewall-cmd --permanent --add-port=3306/tcp
firewall-cmd --reload
firewall-cmd --list-all
# 如果要修改或刪除防火牆規則nano /etc/firewalld/zones/public.xml


# 增加 mysqlclient 帳號
useradd -m mysqlclient -s /bin/bash
passwd mysqlclient

# 啟動服務
/etc/init.d/mysql start

# LOG
/var/lib/mysql/centos7-maria10.err

# 查看 MySQL 版本
mysql --version


# ----- 4-啟動 MariaDB --------------------------------------------------------------------------------

mysql -h localhost -u root -p
# 輸入 root 密碼

CREATE DATABASE BASEBALLDATABANK; # 創建資料庫
CREATE USER 'mlb'@'localhost' IDENTIFIED BY 'MajorLeagueBaseball'; # 創建使用者和密碼
GRANT ALL ON BASEBALLDATABANK.* TO 'mlb'@'localhost'; # 給予使用者權限