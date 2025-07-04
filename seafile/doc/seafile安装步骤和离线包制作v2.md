[TOC]

# 一、脱机安装

## 1.1、deb环境安装

上传离线包(deb.tar)到/opt 目录下

~~~bash
tar xf /opt/deb.tar  -C  /opt/
mv /etc/apt/sources.list /etc/apt/sources.list.bak

cat > /etc/apt/sources.list << 'EOF'
deb [trusted=yes] file:///opt/   deb/
EOF
apt-get update
apt-get install -y python3 python3-setuptools python3-pip python3-ldap memcached openjdk-8-jre \
    libmemcached-dev libreoffice-script-provider-python libreoffice pwgen curl nginx libmysqlclient-dev mariadb-server
~~~



## 1.2、pip3环境安装

上传离线包(pip3.tar.gz)到/opt 目录下

~~~bash
tar xzf /opt/pip3.tar.gz  -C /opt
pip3 install --no-index -f file:///opt/seafile-python-request   /opt/seafile-python-request/*
~~~

## 1.3、配置redis环境

1. 安装redis

2. 安装 RedisJson

   在 redis 安装目录下新建 [module](https://so.csdn.net/so/search?q=module&spm=1001.2101.3001.7020) 文件夹，把 rejson.so 放到 module 文件夹中

   修改 rejson.so 为可执行权限

   ~~~bash
   chmod +x rejson.so
   ~~~

3. 修改 redis.conf ，搜索 loadmodule 添加下列内容

   ~~~bash
   loadmodule /usr/local/redis-6.2.6/module/rejson.so
   ~~~

4. 重启redis

   ~~~bash
   /usr/local/redis-6.2.6/bin/redis-server conf/redis.conf
   ~~~

   

## 1.4、安装seafile服务。

上传安装包（seafile-pro-server_9.0.14_x86-64.tar.gz）到/opt目录下

上传执行脚本包（seafile-9.0_ubuntu）到/opt目录下

~~~bash
bash seafile-9.0_ubuntu 9.0.14
~~~

等待安装完成

安装成功后显示一下内容

~~~bash
Your Seafile server is installed
  -----------------------------------------------------------------

  Server Address:      http://127.0.0.1
  Seafile Admin:       admin@seafile.local
  Admin Password:      haeR8oo3
  Seafile Data Dir:    /opt/seafile/seafile-data
  Seafile DB Credentials:  Check /opt/seafile.my.cnf
  Root DB Credentials:     Check /root/.my.cnf
  This report is also saved to /opt/seafile/aio_seafile-server.log

  Next you should manually complete the following steps
  -----------------------------------------------------------------

  1) Log in to Seafile and configure your server domain via the system
     admin area if applicable.
  2) If this server is behind a firewall, you need to ensure that
     tcp port 80 is open.
  3) Check https://manual.seafile.com/config/sending_email/
     for instructions on how to use an existing email account to send email via SMTP.

  Optional steps
  -----------------------------------------------------------------

  1) Check seahub_settings.py and customize it to fit your needs. Consult
     https://manual.seafile.com/config/seahub_settings_py/ for possible switches.
  2) Setup NGINX with official SSL certificate, we suggest you use Let’s Encrypt. Check
     https://manual.seafile.com/deploy/https_with_nginx/
  3) Secure server with iptables based firewall. For instance: UFW or shorewall
  4) Implement a backup routine for your Seafile server.

  Seafile support options
  -----------------------------------------------------------------

  For free community support visit:   https://bbs.seafile.com
  For paid commercial support visit:  https://seafile.com

~~~

## 1.5、配置redis文件更新消息脚本

上传安装包（handle_redis_msg.py、redis_update.py）到/opt/seafile/seafile-pro-server-9.0.14目录

1. 修改seafile.conf文件

~~~bash
cd /opt/seafile/conf
vim seafevents.conf
~~~

2. 在配置文件中添加

~~~bash
[EVENTS PUBLISH]
## must be "true" to enable publish events messages 
enabled = true
## message format: repo-update\t{{repo_id}}}\t{{commit id}}
## Currently only support redis message queue 
mq_type =redis 

[ REDIS] 
## redis use the 0 database and "repo_update" channel 
server =192.168.1.77 
port =6379 
~~~

3. 复制配置

~~~bash
cp /opt/seafile/conf/seafile.conf /opt/seafile-data
~~~

4. 重启启动服务

~~~bash
su - seafile
./seafile.sh restart
../seahub.sh restart
~~~

5. 配置环境变量

~~~bash
export SEAFILE_CONF_DIR=/opt/seafile/seafile-data   
export PYTHONPATH=/opt/seafile/seafile-server-latest/seahub/thirdpart
~~~

6. 启动服务

~~~bash
python3 redis_update.py
~~~

## 1.6、安装文件挂载服务

1. 新建挂载目录

~~~bash
mkdir /opt/data-dir
~~~

2. 执行挂载命令

~~~bash
./seaf-fuse.sh start -f /opt/data-dir/
~~~

## 1.7、安装seafile的ES服务

1. 安装open-jdk

~~~bash
sudo apt-get install openjdk-8-jdk
~~~

2. 官网查找需要的es版本

   es官网：https://www.elastic.co/cn/downloads/elasticsearch

   点击如下图【apt-get】

   查找自己想要的版本，点击使用deb方式安装

3. 下载指定版本ES、安装

```bash
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.16.2-amd64.deb
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.16.2-amd64.deb.sha512
shasum -a 512 -c elasticsearch-7.16.2-amd64.deb.sha512 
sudo dpkg -i elasticsearch-7.16.2-amd64.deb
```

4. 修改配置文件elasticsearch.yml

~~~bash
vi /etc/elasticsearch/elasticsearch.yml
~~~

5. 启动es

~~~bash
systemctl enable elasticsearch.service    #设置es开机自启动
sudo systemctl start elasticsearch.service    #启动es
sudo systemctl stop elasticsearch.service    #停止es


#查看es运行状态
service elasticsearch status

#查看报错日志
tail -f /var/log/elasticsearch/elasticsearch.log
~~~

6. 检查是否运行正常

~~~bash
curl localhost:9200
~~~

7. 配置seafile的ES

~~~bash
cd /opt/seafile/conf
vim seafevents.conf
~~~

8. 增加配置文件

~~~ bash
[INDEX FILES]
external_es_server = true
es_host = 127.0.0.1
es_port = 9200
enabled = true
interval = 10m
~~~

9. 重启seafile服务

## 1.8、文件在线预览（libreoffice）

1. 打开配置文件

~~~bash
vim conf/seafevent.conf
~~~

2. 添加配置

~~~bash
[OFFICE CONVERTER]
enabled=true
~~~



# 二、离线包制

## 2.1、Ubuntu

### 在外网环境准备

#### 2.1.1下载离线deb包

1. 下载deb包

```bash
rm -rf  /var/cache/apt/archives/*   #清理缓存目录\
#下载deb包(需要什么包可以查询相应版本seafile的安装脚本) 
apt-get install -d python3 python3-setuptools python3-pip python3-ldap memcached openjdk-8-jre libmemcached-dev libreoffice-script-provider-python libreoffice pwgen curl nginx libmysqlclient-dev mariadb-server        
mkdir /opt/deb
cp -r /var/cache/apt/archives/*  /opt/deb/
```

2. 建立索引

```bash
apt-get install  dpkg-dev
chmod 777 -R /opt/deb
cd  /opt
dpkg-scanpackages deb /dev/null | gzip > deb/Packages.gz
```

3. 输出结果如下

```bash
dpkg-scanpackages: warning: Packages in archive but missing from override file:
dpkg-scanpackages: warning:  XXXX  XXXXXX   XXXX
dpkg-scanpackages: info: Wrote X entries to output Packages file.
```

4. 可以打包拷贝出来放在离线的环境

~~~bash
cd /opt
tar -cvf deb.tar deb/
~~~

   

#### 2.1.2下载离线Python包

1. 下载python包

```bash
apt  install python3-pip
mkdir  /opt/seafile-python-request
#下载python包(需要什么包可以查询相应版本seafile的安装脚本)
pip3 download -d /opt/seafile-python-request/ --timeout=3600 django==3.2.* future mysqlclient pymysql Pillow pylibmc captcha markupsafe==2.0.1 jinja2 sqlalchemy==1.4.3 psd-tools django-pylibmc django-simple-captcha pycryptodome==3.12.0 cffi==1.14.0 redis -i https://mirrors.aliyun.com/pypi/simple
```

2. 打包拷贝出来放在离线的环境

~~~Bash
cd /opt
tar -zcvf pip3.tar.gz seafile-python-request/
~~~



## 2.2、Centos（其他离线下载、安装方式）

PS. 准备好网络源以及epel源

### 2.2.1、下载依赖

1. 下依赖

```
mkdir  /opt/seafile-repo
#下载repo包(需要什么包可以查询相应版本seafile的安装脚本)
yum install --downloadonly --downloaddir=/opt/seafile-repo python3 python3-setuptools python3-pip python3-ldap memcached openjdk-8-jre libmemcached-dev libreoffice-script-provider-python libreoffice pwgen curl nginx libmysqlclient-dev mariadb-server

```

2. 生成repodata数据

```
yum install createrepo -y
createrepo /opt/seafile-repo

```

3. 打包拷贝出来放在离线的环境

#### 2.2.2、Python包下载方法

1. 下在python包

```
yum  install python3-pip -y
mkdir  /opt/seafile-python-request
#下载python包(需要什么包可以查询相应版本seafile的安装脚本)
pip3 download -d /opt/seafile-python-request/ --timeout=3600 django==3.2.* future mysqlclient pymysql Pillow pylibmc captcha markupsafe==2.0.1 jinja2 sqlalchemy==1.4.3 psd-tools django-pylibmc django-simple-captcha pycryptodome==3.12.0 cffi==1.14.0 redis -i https://mirrors.aliyun.com/pypi/simple

```

2. 打包拷贝出来放在离线的环境

## 2.3 centos在离线环境下

上传离线包到/opt 目录下

### 2.3.1、安装yum包

```
tar xf seafile-repo.tar -C /opt/
mkdir  /etc/yum.repo.d/bak
mv /etc/yum.repo.d/*.repo /etc/yum.repo.d/bak/

cat > /etc/yum.repo.d/seafile-repo.repo << 'EOF'
[seafile]
name=seafile
baseurl=file:///opt/seafile-repo
gpgcheck=0
enabled=1
EOF
yum clean all && yum  makecached
yum install  -y  XXXX XXXX  XXX

```

### 2.3.2、python包安装

```
tar xf /opt/seafile-python-request.tar  -C /opt
pip3 install --no-index -f file:///opt/seafile-python-request   /opt/seafile-python-request/*

```

