# ----- 1-設定 Server ---------------------------------------------------------------------------------

# 延續使用 hadoop 的環境，繼續安裝 Hive
# Hive 是需要透過 meatstor 將 Hive 的 meta table and patition 存到關聯式資料庫中。設定 metastore 有三種模式：Embedded Mode, Local Mode, Remote Mode.
# 其中 Embedded Mode 適用於測試模式。
# 在 Local Mode 下，Hive server 和 metastore server 在同一個進程中運行，但關聯式資料庫則是在不同進程中運行，且可以安裝在不同主機上。
# 最後，在 Remote Mode 中，metastore server 有一個自己的 JVM 進程。HiveServer2, Hive CLI 等其他進程透過 Thrift 網絡 API 和 metastor server 進行通信（可從 hive.metastore.uris 中設定）。而 metastore server 和 關聯式資料庫則是使用 JDBC 聯繫(可從 javax.jdo.option.ConnectionURL 中設定)。HiveServer, metastor server, database 都可以在同一個主機上，但是在單獨的主機上運行 HiveServer 可以提供更好的 availability 和 scalability。此外，Remote Mode 的優點是只有metastore server 會有 JDBC 的登入訊息，而 client 則不會有。

# 這邊是使用 Remote Mode

# 各節點的 service 配置如下
# centos7-hd0 nn rm hs2
# centos7-hd1 dn nm ms  maria
# centos7-hd2 dn nm hs2
# centos7-hd3 dn nm hs2
# nn: NameNode, dn: DataNode
# rm: ResouceManager, nm: NodeManager
# ms: MetastoreServer, hs2: HiveServer2
# maria: MariaDB


# 在 MariaDB 建立一個 database 和 user
CREATE DATABASE HADOOP;
GRANT ALL ON HADOOP.* TO 'hadoop'@'192.168.0.%' IDENTIFIED BY 'hadoop';
GRANT ALL ON HADOOP.* TO 'hadoop'@'localhost' IDENTIFIED BY 'hadoop';
FLUSH PRIVILEGES;

# ----- 2-Hive ----------------------------------------------------------------------------------------


# 以 root 身份登入
wget http://apache.stu.edu.tw/hive/hive-2.1.1/apache-hive-2.1.1-bin.tar.gz
tar -xzv -f apache-hive-2.1.1-bin.tar.gz -C /usr/local/
mv /usr/local/apache-hive-2.1.1-bin /usr/local/hive-2.1.1
chown -R hadoop:hadoop /usr/local/hive-2.1.1/

# 登出 root 身份，改以 hadoop 帳號登入 metastore server(centos7-hd1) 主機
exit


cd /usr/local/hive-2.1.1

cp conf/hive-default.xml.template conf/hive-default.xml
cp conf/hive-env.sh.template conf/hive-env.sh
cp conf/hive-log4j.properties.template conf/hive-log4j.properties

# 設定 Hive 的環境變數
nano conf/hive-env.sh
HADOOP_HOME=$HADOOP_HOME
export HIVE_CONF_DIR=$HIVE_HOME/conf
export HIVE_AUX_JARS_PATH=$HIVE_HOME/lib

# 加入 Hive config 檔， Hive 會優先讀取 hive-site.xml 的設定，之後才會讀取 hive-default.xml 的設定
# metastore server(centos7-hd1) 的 config 檔如下
nano conf/hive-site.xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:mysql://centos7-hd0:3306/HADOOP?createDatabaseIfNotExist=true</value>
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
  <property>
    <name>hive.metastore.warehouse.dir</name>
    <value>/user/hive/warehouse</value>
  </property>
</configuration>

# Hive client(非metastore server ，但需要連Hive的主機)的 config 檔如下
nano conf/hive-site.xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>hive.metastore.warehouse.dir</name>
    <value>/user/hive/warehouse</value>
    <description>default location for Hive tables</description>
  </property>
  <property>
    <name>hive.metastore.uris</name>
    <value>thrift://centos7-hd1:9083</value>
    <description>host and port for the Thrift metastore server</description>
  </property>
</configuration>



# 由於 Hive 的 lib 庫沒有 MariaDB connector java ，因此我們必須自己下載
wget https://downloads.mariadb.com/Connectors/java/connector-java-1.5.9/mariadb-java-client-1.5.9.jar
# 在 metastore server(centos7-hd1) 主機上，將 MariaDB connector java 複製到 Hive 的 lib 庫裡
cp ~/mariadb-java-client-1.5.9.jar /usr/local/hive-2.1.1/lib/

# 將 Hive 底下的 scripts 檔中的 schema 匯入 MariaDB，需選擇和 Hive 版本匹配的 schema 檔案 
# 進到 MariaDB 中的 HADOOP database
mysql -u hadoop -p HADOOP
SOURCE /usr/local/hive-2.1.1/scripts/metastore/upgrade/mysql/hive-schema-2.1.0.mysql.sql


# 再有安裝 Hive 的主機設定環境變數
nano /home/hadoop/.bashrc
export HIVE_HOME=/usr/local/hive-2.1.1
export PATH=$PATH:$HIVE_HOME/bin:$HIVE_HOME/conf

source ~/.bashrc

# ----- 3-Start Hive ----------------------------------------------------------------------------------

# 從 client 端連接到 Hive 之前，需要先開啟 metastore server 
# 以 hadoop 身分登入 centos7-hd1
hive --service metastore

# 從任一 client(假設使用 cnetos7-hd0) 端執行 hiveserver2
hive --service hiveserver2

# 從第三台主機登入 Beeline
/urs/local/hive-2.1.1/bin/beeline --color=true
# 進到 beeline 的 shell 後
!connect jdbc:hive2://centos7-hd0:10000

# ----- 4-使用 Hive beeline ---------------------------------------------------------------------------

# 以 hadoop 身分登入 centos7-hd0(hadoop master)
# 先去下載美國職棒大聯盟的資料
wget http://seanlahman.com/files/database/baseballdatabank-2017.1.zip

# 使用zip解壓縮
unzip baseballdatabank-2017.1.zip

# 將資料上傳到 Hadoop
# 使用 -copyFromLocal 時檔案重複會體醒。使用 -put 則可以接受 stdin，而且當檔案重複時會直接覆蓋。
hdfs dfs -mkdir -p /user/data/baseball
hdfs dfs -put ~/baseballdatabank-2017.1/core/Master.csv /user/data/baseball
hdfs dfs -put ~/baseballdatabank-2017.1/core/Batting.csv /user/data/baseball
hdfs dfs -put ~/baseballdatabank-2017.1/core/Pitching.csv /user/data/baseball
hdfs dfs -put ~/baseballdatabank-2017.1/core/Fielding.csv /user/data/baseball

# 登入 beeline shell
/urs/local/hive-2.1.1/bin/beeline --color=true
!connect jdbc:hive2://centos7-hd0:10000

# 創建資料庫
create database BASEBALL_2017;
# 創建 table
create table BASEBALL_2017.MASTER( 
  playerID STRING, 
  birthYear INT, 
  birthMonth INT, 
  birthDay INT, 
  birthCountry STRING, 
  birthState STRING, 
  birthCity STRING, 
  deathYear INT, 
  deathMonth INT,
  deathDay INT, 
  deathCountry STRING, 
  deathState STRING, 
  deathCity STRING,
  nameFirst STRING, 
  nameLast STRING, 
  nameGiven STRING,
  weight INT, 
  height INT, 
  bats STRING, 
  throws STRING,
  debut STRING, 
  finalGame STRING, 
  retroID STRING, 
  bbrefID STRING
) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' ;

# 從 Hadoop 匯入資料
# 從本機匯入資料： LOAD DATA LOCAL INPATH "~/baseballdatabank-2017.1/core/master.csv" OVERWRITE INTO TABLE MASTER;
LOAD DATA INPATH "/user/data/baseball/Master.csv" OVERWRITE INTO TABLE MASTER;

# 使用 Hiveql 查詢資料
USE BASEBALL_2017;
SELECT * FROM MASTER WHERE nameLast = 'Chen';