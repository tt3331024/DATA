# ----- 1-設定 Server ----------------------------------------------------------------------------------
# 延續使用 hadoop 的環境，繼續安裝 Hive
# 在同台主機上需要 MariaDB 做為 Hive 元數據庫的存放地，以支持多用戶連接

# 在 MariaDB 建立一個 database 和 user
CREATE DATABASE HADOOP;
GRANT ALL ON HADOOP.* TO 'hadoop'@'localhost' IDENTIFIED BY 'hadoop';
FLUSH PRIVILEGES;

# ----- 2-Hive -----------------------------------------------------------------------------------------


# 以 root 身份登入
wget http://apache.stu.edu.tw/hive/hive-2.1.1/apache-hive-2.1.1-bin.tar.gz
tar -xzv -f apache-hive-2.1.1-bin.tar.gz -C /usr/local/
mv /usr/local/apache-hive-2.1.1-bin /usr/local/hive-2.1.1
chown -R hadoop:hadoop /usr/local/hive-2.1.1/

# 登出 root 身份，改以 hadoop 帳號登入
exit


# 下載 MariaDB connector java
wget https://downloads.mariadb.com/Connectors/java/connector-java-1.5.9/mariadb-java-client-1.5.9.jar

cd /usr/local/hive-2.1.1

cp conf/hive-default.xml.template conf/hive-default.xml
cp conf/hive-env.sh.template conf/hive-env.sh

# 將 MariaDB connector java 複製到 Hive 的 lib 庫裡
cp ~/mariadb-java-client-1.5.9.jar lib/

# 設定 Hive 的環境變數
nano conf/hive-env.sh
HADOOP_HOME=$HADOOP_HOME
export HIVE_CONF_DIR=$HIVE_HOME/conf
export HIVE_AUX_JARS_PATH=$HIVE_HOME/lib

# 加入 Hive config 檔， Hive 會優先讀取 hive-site.xml 的設定，之後才會讀取 hive-default.xml 的設定
nano conf/hive-site.xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:mysql://localhost:3306/HADOOP</value>
    <description>JDBC connect string for a JDBC metastore</description>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionDriverName</name>
    <value>org.mariadb.jdbc.Driver</value>
    <description>Driver class name for a JDBC metastore</description>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionUserName</name>
    <value>hadoop</value>
    <description>username to use against metastore database</description>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionPassword</name>
    <value>hadoop</value>
    <description>password to use against metastore database</description>
  </property>
</configuration>


# 將 Hive 底下的 scripts 檔中的 schema匯入 MariaDB 
# 進到 MariaDB 中的 HADOOP database
mysql -u hadoop -p HADOOP
source scripts/metastore/upgrade/mysql/hive-schema-2.1.0.mysql.sql


# 設定 Hive 的家目錄
nano /home/hadoop/.bashrc
export HIVE_HOME=/usr/local/hive-2.1.1
export PATH=$PATH:$HIVE_HOME/bin:$HIVE_HOME/conf

source ~/.bashrc

# ----- 3-Start Hive -----------------------------------------------------------------------------------

# 執行 Hive
Hive

