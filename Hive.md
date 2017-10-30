### 1-設定 Server

延續使用 hadoop 的環境，繼續安裝 Hive  
Hive 是需要透過 meatstor 將 Hive 的 meta table and patition 存到關聯式資料庫中。設定 metastore 有三種模式：Embedded Mode, Local Mode, Remote Mode.  
1. Embedded Mode 適用於測試模式。  
2. 在 Local Mode 下，Hive server 和 metastore server 在同一個進程中運行，但關聯式資料庫則是在不同進程中運行，且可以安裝在不同主機上。  
3. 在 Remote Mode 中，metastore server 有一個自己的 JVM 進程。HiveServer2, Hive CLI 等其他進程透過 Thrift 網絡 API 和 metastor server 進行通信（可從 hive.metastore.uris 中設定）。而 metastore server 和 關聯式資料庫則是使用 JDBC 聯繫(可從 javax.jdo.option.ConnectionURL 中設定)。HiveServer, metastor server, database 都可以在同一個主機上，但是在單獨的主機上運行 HiveServer 可以提供更好的 availability 和 scalability。此外，Remote Mode 的優點是只有metastore server 會有 JDBC 的登入訊息，而 client 則不會有。

這邊是使用 Remote Mode

各節點的 service 配置如下  
centos7-hd0 nn rm hs2  
centos7-hd1 dn nm ms  maria  
centos7-hd2 dn nm hs2  
centos7-hd3 dn nm hs2  
nn: NameNode, dn: DataNode  
rm: ResouceManager, nm: NodeManager  
ms: MetastoreServer, hs2: HiveServer2  
maria: MariaDB


在 MariaDB 建立一個 database 和 user

    CREATE DATABASE HADOOP;
    GRANT ALL ON HADOOP.* TO 'hadoop'@'192.168.0.%' IDENTIFIED BY 'hadoop';
    GRANT ALL ON HADOOP.* TO 'hadoop'@'localhost' IDENTIFIED BY 'hadoop';
    FLUSH PRIVILEGES;

### 2-Hive

**以 root 身份登入**  
在所有機器下下載Hive並解壓縮。

    wget http://apache.stu.edu.tw/hive/hive-2.1.1/apache-hive-2.1.1-bin.tar.gz
    tar -xzv -f apache-hive-2.1.1-bin.tar.gz -C /usr/local/
    mv /usr/local/apache-hive-2.1.1-bin /usr/local/hive-2.1.1
    chown -R hadoop:hadoop /usr/local/hive-2.1.1/

登出root身份，改以hadoop帳號登入metastore server(centos7-hd1)主機

    cd /usr/local/hive-2.1.1

    cp conf/hive-default.xml.template conf/hive-default.xml
    cp conf/hive-env.sh.template conf/hive-env.sh
    cp conf/hive-log4j2.properties.template conf/hive-log4j2.properties

設定hive-env.sh檔中的環境變數

    nano conf/hive-env.sh
     HADOOP_HOME=$HADOOP_HOME
     export HIVE_CONF_DIR=$HIVE_HOME/conf
     export HIVE_AUX_JARS_PATH=$HIVE_HOME/lib

新增Hive config檔，Hive會優先讀取hive-site.xml 的設定，之後才會讀取hive-default.xml的設定  
metastore server(centos7-hd1) 的config檔如下

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

Hive client(非metastore server ，但需要連Hive的主機)的config檔如下

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


再有安裝 Hive 的主機設定環境變數

  nano /home/hadoop/.bashrc
   export HIVE_HOME=/usr/local/hive-2.1.1
   export PATH=$PATH:$HIVE_HOME/bin:$HIVE_HOME/conf
  source ~/.bashrc


由於Hive的lib庫沒有MariaDB connector java，因此我們必須自己下載

    wget https://downloads.mariadb.com/Connectors/java/connector-java-1.5.9/mariadb-java-client-1.5.9.jar

在metastore server(centos7-hd1)主機上，將MariaDB connector java複製到Hive的lib庫裡

    cp ~/mariadb-java-client-1.5.9.jar /usr/local/hive-2.1.1/lib/

將Hive底下的scripts檔中的schema匯入MariaDB，需選擇和Hive版本匹配的schema檔案 
進到MariaDB中的HADOOP database
mysql -u hadoop -p HADOOP
SOURCE /usr/local/hive-2.1.1/scripts/metastore/upgrade/mysql/hive-schema-2.1.0.mysql.sql
# 可使用`schematool -initSchema -dbType mysql`直接匯入schema


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

