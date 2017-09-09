# ----- 1-設定 Server ---------------------------------------------------------------------------------

# 1. 除了安裝 Ambari 的 user 外，不可以有其他 user (四台機器都是)
# 2. 設定FQDN(四台機器都要)
nano /etc/hosts
192.168.0.100 entos7-hd0.example.com entos7-hd0
192.168.0.101 entos7-hd1.example.com entos7-hd1
192.168.0.102 entos7-hd2.example.com entos7-hd2
192.168.0.103 entos7-hd3.example.com entos7-hd3
# 3. 安裝好 Oracle JDK(Ambari server 需要)
# 4. ssh password-less(Ambari server 到其他機器)
# 5. 關閉防火牆(四台機器都要)
systemctl stop firewall-server
# 6. 安裝並開通ntpd(四台機器都要)
yum install ntp
systemctl start ntpd
# 7. 安裝好 MariaDB，並建立一個 database 和 user(可在任一主機上安裝)
CREATE DATABASE AMBARI;
GRANT ALL ON AMBARI.* TO 'ambari'@'192.168.0.%' IDENTIFIED BY 'ambari';
GRANT ALL ON AMBARI.* TO 'ambari'@'localhost' IDENTIFIED BY 'ambari';
FLUSH PRIVILEGES;


# ----- 1-Ambari ----------------------------------------------------------------------------------------

# 從網站下載 Ambari repository 
wget -nv http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.5.0.3/ambari.repo -O /etc/yum.repos.d/ambari.repo
# 可以在 /etc/yum.repos.d/ambari.repo 看到 Ambari repository 的設置

# 執行 yum 來安裝 Ambari
yum install ambari-server


# 將 /var/lib 底下的 Ambari 檔中的 schema 匯入 MariaDB
# 進到 MariaDB 中的 AMBARI database
mysql -u ambari -p AMBARI
SOURCE /var/lib/ambari-server/resources/Ambari-DDL-MySQL-CREATE.sql;

# 下載 mysql/mariadb 的 connector.jar 檔
yum install mysql-connector-java*

# 開始 Ambari 設置
ambari-server setup

Using python  /usr/bin/python
Setup ambari-server
Checking SELinux...
SELinux status is 'enabled'
SELinux mode is 'enforcing'
Temporarily disabling SELinux
WARNING: SELinux is set to 'permissive' mode and temporarily disabled.
OK to continue [y/n] (y)? # 如果沒有暫時禁用SELinux，就會收到警告，接受預設(y)，然後繼續
Customize user account for ambari-server daemon [y/n] (n)? # 選擇預設值(n)，繼續使用 root 身份設定 Ambari
Adjusting ambari-server permissions and ownership...
Checking firewall status...
WARNING: iptables is running. Confirm the necessary Ambari ports are accessible. Refer to the Ambari documentation for more details on ports.
OK to continue [y/n] (y)? # 如果沒暫時停用防火牆，就會收到警告，接受預設(y)，然後繼續
Checking JDK...
[1] Oracle JDK 1.8 + Java Cryptography Extension (JCE) Policy Files 8
[2] Oracle JDK 1.7 + Java Cryptography Extension (JCE) Policy Files 7
[3] Custom JDK
==============================================================================
Enter choice (1): # 選擇 JDK，1, 2是下載 Oracle JDK，由於本機已經有安裝好的 JDK，所以選擇 3
WARNING: JDK must be installed on all hosts and JAVA_HOME must be valid on all hosts.
WARNING: JCE Policy files are required for configuring Kerberos security. If you plan to use Kerberos,please make sure JCE Unlimited Strength Jurisdiction Policy Files are valid on all hosts.
Path to JAVA_HOME: # 這邊要設定JAVA_HOME 的位置 /usr/java/jdk1.8.0_141
Validating JDK on Ambari Server...done.
Completing setup...
Configuring database...
Enter advanced database configuration [y/n] (n)? # 這邊請選擇(y)，使用現有的 database。若選(n)，則是使用預設的 PostgreSQL database
==============================================================================
Choose one of the following options:
[1] - PostgreSQL (Embedded)
[2] - Oracle
[3] - MySQL / MariaDB
[4] - PostgreSQL
[5] - Microsoft SQL Server (Tech Preview)
[6] - SQL Anywhere
[7] - BDB
==============================================================================
Enter choice (1): # 根據使用者所需存放的 database
Hostname (localhost): # database 所在的主機名稱
Port (3306): # database 的 port
Database name (ambari): # 資料庫名稱
Username (ambari): # database user name
Enter Database Password (bigdata): # database user password
Re-enter password:
Configuring ambari database...
Copying JDBC drivers to server resources...
Configuring remote database connection properties...
WARNING: Before starting Ambari Server, you must run the following DDL against the database to create the schema: /var/lib/ambari-server/resources/Ambari-DDL-MySQL-CREATE.sql
Proceed with configuring remote database connection properties [y/n] (y)? # 繼續配置遠端數據庫，選擇(y)
Extracting system views...
ambari-admin-2.5.0.3.7.jar
...........
Adjusting ambari-server permissions and ownership...
Ambari Server 'setup' completed successfully.
# 看到 successfully 就代表完成設置


# 啟動 Ambari server
ambari-server start --skip-database-check

# 可在網址列打上 centos7-hd0:8080，進入ambari
# 登入帳號和密碼都為admin
