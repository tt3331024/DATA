# ----- 1-設定 Server ----------------------------------------------------------------------------------

# 安裝 VM CentOS-7 ，機器名稱為： centos7-mongo34 
# 硬體規格：Disk=60G(single file) RAM=2GB Network=Bridge ID/PWD=root/********


# ----- 2-MongoDB --------------------------------------------------------------------------------------

# 以 root 身份登入
# 新建一個文檔，紀錄下載網址資訊，以便使用 yum 直接安裝 ＭongoDB
nano /etc/yum.repos.d/mongodb-org-3.4.repo
[mongodb-org-3.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/3.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-3.4.asc

# 使用 yum 安裝 MongoDB
yum install -y mongodb-org


# ----- 3-start MongoDB --------------------------------------------------------------------------------

# 創建一個帳號，供未來 client 端連線 MongoDB 時使用
useradd mongoclient
passwd mongoclient

# 進入 MongoDB
service mongod start 	# 啟動 MongoDB service

# 登出，使用 mongoclient 登入
exit

mongo 					# 進入 MongoDB 指令

# 建立 MongoDB admin 帳號
use admin  # 切換到 admin database
# 新建使用者叫 Admin ，密碼為 1234 ，有所有資料庫的讀寫權限，能管理所有的資料庫，所有使用者的管理人員，
db.createUser({
	user:"Admin", pwd:"****", 
	roles:[
	  {role:"readWriteAnyDatabase", db:"admin"}, 
	  {role:"dbAdminAnyDatabase", db:"admin"}, 
	  {role:"userAdminAnyDatabase", db:"admin"}, 
	  {role:"clusterAdmin", db:"admin"}
	]
})

# 離開 mongodb
exit

# 開啟登入認證功能
# 修改 mongo config 檔
nano /etc/mongod.conf
# 找到 # security: 把註解拿掉，並修改
security:
  authorization: enabled

service mongod restart


# ----- 4-MongoDB command ------------------------------------------------------------------------------

# 進入 mongo 後

db.auth("<username>", "<password>")		# 使用者登入
show dbs 								# 展示所有資料庫
db 										# 展示現在所在的資料庫名稱
use <dbname>							# 切換到資料庫中，當不是現存資料庫時，等於創建一個新的資料庫
show tables 							# 展示所有表
show users 								# 展示所有使用者
db.createUser({							# 新建使用者
	user:"Admin",						# 使用者名稱
	pwd:"1234", 						# 使用者密碼
	roles:[								# 使用者角色
		{role:"readWriteAnyDatabase", db:"admin"},		# 有所有資料庫的讀寫權限
		{role:"dbAdminAnyDatabase", db:"admin"},		# 所有資料庫的管理者
		{role:"userAdminAnyDatabase", db:"admin"},		# 管理所有資料庫的使用者
		{role:"clusterAdmin", db:"admin"}				# 
	]
})
db.runCommand({connectionStatus : 1})	# 查詢當前使用者是誰

db.<tablename>.insertOne({<key>:<value>})	# 在 tablename 表的 key 欄新增一個 value 值
db.<tablename>.find({<key>:<value>})		# 在 tablename 表的 key 欄搜尋值是 value 。類似 SELECT * FROM TABLENAME WHERE KEY = VALUE

