# docker部署kodbox+onlyoffice服务

## 1、设置kodbox环境和文件

### 1.1 设置环境文件

```bash
# 创建目录并进入文件
mkdir kodbox && cd kodbox

# 设置环境变量
cat > .env <<EOF
MYSQL_ROOT_PASSWORD=       #数据库ROOT密码
MYSQL_DATABASE=            #新建数据库名称
MYSQL_USER=                #新建数据库用户名
MYSQL_PASSWORD=            #新建数据库用户密码
EOF
```

### 1.2、生成docker-compose.yaml文件

```bash
#新建docker-compose.yaml文件
touch docker-compose.yaml

# docker-compose.yaml文件内容
cat > docker-compose.yaml <<EOF
version: '3.0'
services:
  kodcloud:
    container_name: kodcloud
    image: kodcloud/kodbox
    restart: always
    volumes:
      - kodcloud_data:/var/www/html
      - ./background/nginx.conf:/etc/nginx/nginx.conf
      - ./background/docker-vars.ini:/usr/local/etc/php/conf.d/docker-vars.ini
      - ./csr/nginx.pem:/etc/nginx/nginx.pem
      - ./csr/nginx.key:/etc/nginx/nginx.key
    ports:
      - 6080:80
      - 6443:443
    depends_on:
      - mysql
      - redis
    networks:
      - kodbox_network

  mysql:
    container_name: kodbox_mysql
    image: mysql:8.0.29
    restart: always
    volumes:
      - database_mysql:/var/lib/mysql
    ports:
      - 9004:3306
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
    networks:
      - kodbox_network

  redis:
    container_name: kodbox_redis
    image: redis:5.0
    restart: always
    volumes:
      - database_redis:/data
    ports:
      - 9005:6379
    networks:
      - kodbox_network

  onlyoffice:
    image: kodcloud/kodoffice:7.4.1.1
    container_name: onlyoffice
    restart: always
    ports:
      - "9006:80"
      - "9012:443"
    stdin_open: true
    volumes:
      - ./DocumentServer/data:/var/www/onlyoffice/Data
      - ./background/default.json:/etc/onlyoffice/documentserver/default.json
    environment:
      - JWT_ENABLED=false
    networks:
      - kodbox_network

volumes:
  database_redis:
  database_mysql:
  kodcloud_data:

networks:
    kodbox_network:
        driver: bridge
        ipam:
            config:
                - subnet: 172.45.0.0/24
EOF
```

### 1.3、生成docker-vars.ini文件

```bash
#新建docker-vars.ini文件
cd background
touch docker-vars.ini

# docker-vars.ini文件内容
cat > docker-vars.ini <<EOF
cgi.fix_pathinfo=1
upload_max_filesize = 10240M
post_max_size = 10240M
memory_limit = 2048M
max_execution_time = 3600
max_input_time = 3600
EOF
```

### 1.4、生成nginx.conf文件

```bash
#新建nginx.conf文件
cd background
touch nginx.conf

# nginx.conf文件内容
cat > nginx.conf <<EOF
#user  nobody;
worker_processes auto;
worker_rlimit_nofile 51200;
#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        run/nginx.pid;
# Enables the use of JIT for regular expressions to speed-up their processing.
pcre_jit on;

# Includes files with directives to load dynamic modules.
include /etc/nginx/modules/*.conf;

events {
    use epoll;
    worker_connections 51200;
    multi_accept on;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';

    #access_log  logs/access.log  main;
    server_names_hash_bucket_size 512;
    client_header_buffer_size 32k;
    large_client_header_buffers 4 32k;
    client_max_body_size 1024M;
    client_body_timeout 300s;
    client_body_buffer_size 512k;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;

    fastcgi_send_timeout 3600;
    fastcgi_read_timeout 3600;
    fastcgi_buffer_size 64k;
    fastcgi_buffers 4 64k;
    fastcgi_busy_buffers_size 128k;
    fastcgi_temp_file_write_size 256k;
    fastcgi_intercept_errors on;
    fastcgi_hide_header X-Powered-By;

    gzip on;
    gzip_vary on;
    gzip_comp_level 4;
    gzip_min_length  256;
    gzip_types text/plain application/javascript application/x-javascript application/json application/ld+json application/manifest+json application/rss+xml text/javascript text/css application/xml;
    gzip_proxied expired no-cache no-store private no_last_modified no_etag  auth;
    gzip_disable "MSIE [1-6]\.";
    server_tokens off;

    add_header Referrer-Policy                      "no-referrer"   always;
    add_header X-Content-Type-Options               "nosniff"       always;
    add_header X-Download-Options                   "noopen"        always;
    add_header X-Frame-Options                      "SAMEORIGIN"    always;
    add_header X-Permitted-Cross-Domain-Policies    "none"          always;
    add_header X-Robots-Tag                         "none"          always;
    add_header X-XSS-Protection                     "1; mode=block" always;

    server {
        listen   80; ## listen for ipv4; this line is default and implied
        listen   [::]:80 default ipv6only=on; ## listen for ipv6
        listen   443 ssl;
        http2    on;


        ssl_certificate     /etc/nginx/nginx.pem;
        ssl_certificate_key /etc/nginx/nginx.key;
        ssl_protocols       TLSv1.1 TLSv1.2 TLSv1.3;
        ssl_ciphers         EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:!MD5;
        add_header Strict-Transport-Security "max-age=31536000";
        ssl_prefer_server_ciphers on;
        ssl_session_cache shared:SSL:2m;
        ssl_session_timeout 1h;
        ssl_session_tickets off;


        root /var/www/html;
        index index.php index.html index.htm;
        #return 301 https://$host$request_uri;
        # Make site accessible from http://localhost/
        server_name _;

        # Add stdout logging
        error_log /dev/stdout info;
        access_log /dev/stdout;

        # Add option for x-forward-for (real ip when behind elb)
        #real_ip_header X-Forwarded-For;
        #set_real_ip_from 172.16.0.0/12;

        # pass the PHP scripts to FastCGI server listening on socket
        # enable pathinfo
        location ~ [^/]\.php(/|$) {
            try_files $uri =404;
            fastcgi_pass unix:/var/run/php-fpm.sock;
            fastcgi_index index.php;
            set $path_info $fastcgi_path_info;
            set $real_script_name $fastcgi_script_name;
            if ($fastcgi_script_name ~ "^(.+?\.php)(/.+)$") {
                set $real_script_name $1;
                set $path_info $2;
            }
            fastcgi_param SCRIPT_FILENAME $document_root$real_script_name;
            fastcgi_param SCRIPT_NAME $real_script_name;
            fastcgi_param PATH_INFO $path_info;
            include fastcgi_params;
        }

        location ~ ^/(?:config|data)(?:$|/)  {
            return 404;
        }

        location ~* \.(jpg|jpeg|gif|png|css|js|ico|webp|tiff|ttf|svg)$ {
            expires      30d;
            access_log off;
        }

        location ~ .*\.(js|css)?$ {
            expires      12h;
            access_log off;
        }
        # deny access to . files, for security
        location ~ /\. {
            log_not_found off;
            deny all;
        }

        location ^~ /.well-known {
            allow all;
            auth_basic off;
        }

        location = /favicon.ico {
            log_not_found off;
        }
    }

    include /etc/nginx/sites-enabled/*;
}
#daemon off;
EOF
```

### 1.5、生成default.json文件

```bash
{
  "statsd": {
    "useMetrics": false,
    "host": "localhost",
    "port": "8125",
    "prefix": "ds."
  },
  "log": {
    "filePath": "",
    "options": {
      "replaceConsole": true
    }
  },
  "queue": {
    "type": "rabbitmq",
    "visibilityTimeout": 300,
    "retentionPeriod": 900
  },
  "storage": {
    "name": "storage-fs",
    "fs": {
      "folderPath": "",
      "urlExpires": 900,
      "secretString": "verysecretstring"
    },
    "region": "",
    "endpoint": "http://localhost/s3",
    "bucketName": "cache",
    "storageFolderName": "files",
    "cacheFolderName": "data",
    "urlExpires": 604800,
    "accessKeyId": "AKID",
    "secretAccessKey": "SECRET",
    "sslEnabled": false,
    "s3ForcePathStyle": true,
    "externalHost": ""
  },
  "rabbitmq": {
    "url": "amqp://guest:guest@localhost:5672",
    "socketOptions": {},
    "exchangepubsub": "ds.pubsub",
    "queueconverttask": "ds.converttask",
    "queueconvertresponse": "ds.convertresponse",
    "exchangeconvertdead": "ds.exchangeconvertdead",
    "queueconvertdead": "ds.convertdead",
    "queuedelayed": "ds.delayed"
  },
  "activemq": {
    "connectOptions": {
      "port": 5672,
      "host": "localhost",
      "reconnect": false
    },
    "queueconverttask": "ds.converttask",
    "queueconvertresponse": "ds.convertresponse",
    "queueconvertdead": "ActiveMQ.DLQ",
    "queuedelayed": "ds.delayed",
    "topicpubsub": "ds.pubsub"
  },
  "dnscache": {
    "enable": true,
    "ttl": 300,
    "cachesize": 1000
  },
  "openpgpjs": {
    "config": {},
    "encrypt": {
      "passwords": [
        "verysecretstring"
      ]
    },
    "decrypt": {
      "passwords": [
        "verysecretstring"
      ]
    }
  },
  "bottleneck": {
    "getChanges": {}
  },
  "wopi": {
    "enable": false,
    "host": "",
    "htmlTemplate": "../../web-apps/apps/api/wopi",
    "wopiZone": "external-http",
    "favIconUrlWord": "/web-apps/apps/documenteditor/main/resources/img/favicon.ico",
    "favIconUrlCell": "/web-apps/apps/spreadsheeteditor/main/resources/img/favicon.ico",
    "favIconUrlSlide": "/web-apps/apps/presentationeditor/main/resources/img/favicon.ico",
    "fileInfoBlockList": [
      "FileUrl"
    ],
    "pdfView": [
      "pdf",
      "djvu",
      "xps",
      "oxps"
    ],
    "wordView": [
      "doc",
      "dotx",
      "dotm",
      "dot",
      "fodt",
      "ott",
      "rtf",
      "mht",
      "mhtml",
      "html",
      "htm",
      "xml",
      "epub",
      "fb2",
      "sxw",
      "stw",
      "wps",
      "wpt"
    ],
    "wordEdit": [
      "docx",
      "docm",
      "docxf",
      "oform",
      "odt",
      "txt"
    ],
    "cellView": [
      "xls",
      "xlsb",
      "xltx",
      "xltm",
      "xlt",
      "fods",
      "ots",
      "sxc",
      "xml",
      "et",
      "ett"
    ],
    "cellEdit": [
      "xlsx",
      "xlsm",
      "ods",
      "csv"
    ],
    "slideView": [
      "ppt",
      "ppsx",
      "ppsm",
      "pps",
      "potx",
      "potm",
      "pot",
      "fodp",
      "otp",
      "sxi",
      "dps",
      "dpt"
    ],
    "slideEdit": [
      "pptx",
      "pptm",
      "odp"
    ],
    "publicKey": "BgIAAACkAABSU0ExAAgAAAEAAQD/NVqekFNi8X3p6Bvdlaxm0GGuggW5kKfVEQzPGuOkGVrz6DrOMNR+k7Pq8tONY+1NHgS6Z+v3959em78qclVDuQX77Tkml0xMHAQHN4sAHF9iQJS8gOBUKSVKaHD7Z8YXch6F212YSUSc8QphpDSHWVShU7rcUeLQsd/0pkflh5+um4YKEZhm4Mou3vstp5p12NeffyK1WFZF7q4jB7jclAslYKQsP82YY3DcRwu5Tl/+W0ifVcXze0mI7v1reJ12pKn8ifRiq+0q5oJST3TRSrvmjLg9Gt3ozhVIt2HUi3La7Qh40YOAUXm0g/hUq2BepeOp1C7WSvaOFHXe6Hqq",
    "modulus": "qnro3nUUjvZK1i7UqeOlXmCrVPiDtHlRgIPReAjt2nKL1GG3SBXO6N0aPbiM5rtK0XRPUoLmKu2rYvSJ/Kmkdp14a/3uiEl788VVn0hb/l9OuQtH3HBjmM0/LKRgJQuU3LgHI67uRVZYtSJ/n9fYdZqnLfveLsrgZpgRCoabrp+H5Uem9N+x0OJR3LpToVRZhzSkYQrxnERJmF3bhR5yF8Zn+3BoSiUpVOCAvJRAYl8cAIs3BwQcTEyXJjnt+wW5Q1VyKr+bXp/39+tnugQeTe1jjdPy6rOTftQwzjro81oZpOMazwwR1aeQuQWCrmHQZqyV3Rvo6X3xYlOQnlo1/w==",
    "exponent": "AQAB",
    "privateKey": "MIIEowIBAAKCAQEAqnro3nUUjvZK1i7UqeOlXmCrVPiDtHlRgIPReAjt2nKL1GG3SBXO6N0aPbiM5rtK0XRPUoLmKu2rYvSJ/Kmkdp14a/3uiEl788VVn0hb/l9OuQtH3HBjmM0/LKRgJQuU3LgHI67uRVZYtSJ/n9fYdZqnLfveLsrgZpgRCoabrp+H5Uem9N+x0OJR3LpToVRZhzSkYQrxnERJmF3bhR5yF8Zn+3BoSiUpVOCAvJRAYl8cAIs3BwQcTEyXJjnt+wW5Q1VyKr+bXp/39+tnugQeTe1jjdPy6rOTftQwzjro81oZpOMazwwR1aeQuQWCrmHQZqyV3Rvo6X3xYlOQnlo1/wIDAQABAoIBAQCKtUSBs8tNYrGTQTlBHXrwpkDg+u7WSZt5sEcfnkxA39BLtlHU8gGO0E9Ihr8GAL+oWjUsEltJ9GTtN8CJ9lFdPVS8sTiCZR/YQOggmFRZTJyVzMrkXgF7Uwwiu3+KxLiTOZx9eRhfDBlTD8W9fXaegX2i2Xp2ohUhBHthEBLdaZTWFi5Sid/Y0dDzBeP6UIJorZ5D+1ybaeIVHjndpwNsIEUGUxPFLrkeiU8Rm4MJ9ahxfywcP7DjQoPGY9Ge5cBhpxfzERWf732wUD6o3+L9tvOBU00CLVjULbGZKTVE2FJMyXK9jr6Zor9Mkhomp6/8Agkr9rp+TPyelFGYEz8hAoGBAOEc09CrL3eYBkhNEcaMQzxBLvOGpg8kaDX5SaArHfl9+U9yzRqss4ARECanp9HuHfjMQo7iejao0ngDjL7BNMSaH74QlSsPOY2iOm8Qvx8/zb7g4h9r1zLjFZb3mpSA4snRZvvdiZ9ugbuVPmhXnDzRRMg45MibJeeOTJNylofRAoGBAMHfF/WutqKDoX25qZo9m74W4bttOj6oIDk1N4/c6M1Z1v/aptYSE06bkWngj9P46kqjaay4hgMtzyGruc5aojPx5MHHf5bo14+Jv4NzYtR2llrUxO+UJX7aCfUYXI7RC93GUmhpeQ414j7SNAXec58d7e+ETw+6cHiAWO4uOSTPAoGATPq5qDLR4Zi4FUNdn8LZPyKfNqHF6YmupT5hIgd8kZO1jKiaYNPL8jBjkIRmjBBcaXcYD5p85nImvumf2J9jNxPpZOpwyC/Fo5xlVROp97qu1eY7DTmodntXJ6/2SXAlnZQhHmHsrPtyG752f+HtyJJbbgiem8cKWDu+DfHybfECgYBbSLo1WiBwgN4nHqZ3E48jgA6le5azLeKOTTpuKKwNFMIhEkj//t7MYn+jhLL0Mf3PSwZU50Vidc1To1IHkbFSGBGIFHFFEzl8QnXEZS4hr/y3o/teezj0c6HAn8nlDRUzRVBEDXWMdV6kCcGpCccTIrqHzpqTY0vV0UkOTQFnDQKBgAxSEhm/gtCYJIMCBe+KBJT9uECV5xDQopTTjsGOkd4306EN2dyPOIlAfwM6K/0qWisa0Ei5i8TbRRuBeTTdLEYLqXCJ7fj5tdD1begBdSVtHQ2WHqzPJSuImTkFi9NXxd1XUyZFM3y6YQvlssSuL7QSxUIEtZHnrJTt3QDd10dj",
    "publicKeyOld": "BgIAAACkAABSU0ExAAgAAAEAAQD/NVqekFNi8X3p6Bvdlaxm0GGuggW5kKfVEQzPGuOkGVrz6DrOMNR+k7Pq8tONY+1NHgS6Z+v3959em78qclVDuQX77Tkml0xMHAQHN4sAHF9iQJS8gOBUKSVKaHD7Z8YXch6F212YSUSc8QphpDSHWVShU7rcUeLQsd/0pkflh5+um4YKEZhm4Mou3vstp5p12NeffyK1WFZF7q4jB7jclAslYKQsP82YY3DcRwu5Tl/+W0ifVcXze0mI7v1reJ12pKn8ifRiq+0q5oJST3TRSrvmjLg9Gt3ozhVIt2HUi3La7Qh40YOAUXm0g/hUq2BepeOp1C7WSvaOFHXe6Hqq",
    "modulusOld": "qnro3nUUjvZK1i7UqeOlXmCrVPiDtHlRgIPReAjt2nKL1GG3SBXO6N0aPbiM5rtK0XRPUoLmKu2rYvSJ/Kmkdp14a/3uiEl788VVn0hb/l9OuQtH3HBjmM0/LKRgJQuU3LgHI67uRVZYtSJ/n9fYdZqnLfveLsrgZpgRCoabrp+H5Uem9N+x0OJR3LpToVRZhzSkYQrxnERJmF3bhR5yF8Zn+3BoSiUpVOCAvJRAYl8cAIs3BwQcTEyXJjnt+wW5Q1VyKr+bXp/39+tnugQeTe1jjdPy6rOTftQwzjro81oZpOMazwwR1aeQuQWCrmHQZqyV3Rvo6X3xYlOQnlo1/w==",
    "exponentOld": "AQAB",
    "privateKeyOld": "MIIEowIBAAKCAQEAqnro3nUUjvZK1i7UqeOlXmCrVPiDtHlRgIPReAjt2nKL1GG3SBXO6N0aPbiM5rtK0XRPUoLmKu2rYvSJ/Kmkdp14a/3uiEl788VVn0hb/l9OuQtH3HBjmM0/LKRgJQuU3LgHI67uRVZYtSJ/n9fYdZqnLfveLsrgZpgRCoabrp+H5Uem9N+x0OJR3LpToVRZhzSkYQrxnERJmF3bhR5yF8Zn+3BoSiUpVOCAvJRAYl8cAIs3BwQcTEyXJjnt+wW5Q1VyKr+bXp/39+tnugQeTe1jjdPy6rOTftQwzjro81oZpOMazwwR1aeQuQWCrmHQZqyV3Rvo6X3xYlOQnlo1/wIDAQABAoIBAQCKtUSBs8tNYrGTQTlBHXrwpkDg+u7WSZt5sEcfnkxA39BLtlHU8gGO0E9Ihr8GAL+oWjUsEltJ9GTtN8CJ9lFdPVS8sTiCZR/YQOggmFRZTJyVzMrkXgF7Uwwiu3+KxLiTOZx9eRhfDBlTD8W9fXaegX2i2Xp2ohUhBHthEBLdaZTWFi5Sid/Y0dDzBeP6UIJorZ5D+1ybaeIVHjndpwNsIEUGUxPFLrkeiU8Rm4MJ9ahxfywcP7DjQoPGY9Ge5cBhpxfzERWf732wUD6o3+L9tvOBU00CLVjULbGZKTVE2FJMyXK9jr6Zor9Mkhomp6/8Agkr9rp+TPyelFGYEz8hAoGBAOEc09CrL3eYBkhNEcaMQzxBLvOGpg8kaDX5SaArHfl9+U9yzRqss4ARECanp9HuHfjMQo7iejao0ngDjL7BNMSaH74QlSsPOY2iOm8Qvx8/zb7g4h9r1zLjFZb3mpSA4snRZvvdiZ9ugbuVPmhXnDzRRMg45MibJeeOTJNylofRAoGBAMHfF/WutqKDoX25qZo9m74W4bttOj6oIDk1N4/c6M1Z1v/aptYSE06bkWngj9P46kqjaay4hgMtzyGruc5aojPx5MHHf5bo14+Jv4NzYtR2llrUxO+UJX7aCfUYXI7RC93GUmhpeQ414j7SNAXec58d7e+ETw+6cHiAWO4uOSTPAoGATPq5qDLR4Zi4FUNdn8LZPyKfNqHF6YmupT5hIgd8kZO1jKiaYNPL8jBjkIRmjBBcaXcYD5p85nImvumf2J9jNxPpZOpwyC/Fo5xlVROp97qu1eY7DTmodntXJ6/2SXAlnZQhHmHsrPtyG752f+HtyJJbbgiem8cKWDu+DfHybfECgYBbSLo1WiBwgN4nHqZ3E48jgA6le5azLeKOTTpuKKwNFMIhEkj//t7MYn+jhLL0Mf3PSwZU50Vidc1To1IHkbFSGBGIFHFFEzl8QnXEZS4hr/y3o/teezj0c6HAn8nlDRUzRVBEDXWMdV6kCcGpCccTIrqHzpqTY0vV0UkOTQFnDQKBgAxSEhm/gtCYJIMCBe+KBJT9uECV5xDQopTTjsGOkd4306EN2dyPOIlAfwM6K/0qWisa0Ei5i8TbRRuBeTTdLEYLqXCJ7fj5tdD1begBdSVtHQ2WHqzPJSuImTkFi9NXxd1XUyZFM3y6YQvlssSuL7QSxUIEtZHnrJTt3QDd10dj",
    "refreshLockInterval": "10m"
  },
  "tenants": {
    "baseDir": "",
    "baseDomain": "",
    "filenameSecret": "secret.key",
    "filenameLicense": "license.lic",
    "defaultTenant": "localhost",
    "cache": {
      "stdTTL": 300,
      "checkperiod": 60,
      "useClones": false
    }
  },
  "services": {
    "CoAuthoring": {
      "server": {
        "port": 8000,
        "workerpercpu": 1,
        "mode": "development",
        "limits_tempfile_upload": 504857600,
        "limits_image_size": 26214400,
        "limits_image_download_timeout": {
          "connectionAndInactivity": "2m",
          "wholeCycle": "2m"
        },
        "callbackRequestTimeout": {
          "connectionAndInactivity": "10m",
          "wholeCycle": "10m"
        },
        "healthcheckfilepath": "../public/healthcheck.docx",
        "savetimeoutdelay": 5000,
        "edit_singleton": false,
        "forgottenfiles": "forgotten",
        "forgottenfilesname": "output",
        "maxRequestChanges": 20000,
        "openProtectedFile": true,
        "isAnonymousSupport": true,
        "editorDataStorage": "editorDataMemory",
        "assemblyFormatAsOrigin": true,
        "newFileTemplate": "../../document-templates/new",
        "downloadFileAllowExt": [
          "pdf",
          "xlsx"
        ],
        "tokenRequiredParams": true
      },
      "requestDefaults": {
        "headers": {
          "User-Agent": "Node.js/6.13",
          "Connection": "Keep-Alive"
        },
        "gzip": true,
        "rejectUnauthorized": false
      },
      "autoAssembly": {
        "enable": false,
        "interval": "5m",
        "step": "1m"
      },
      "utils": {
        "utils_common_fontdir": "null",
        "utils_fonts_search_patterns": "*.ttf;*.ttc;*.otf",
        "limits_image_types_upload": "jpg;jpeg;jpe;png;gif;bmp"
      },
      "sql": {
        "type": "postgres",
        "tableChanges": "doc_changes",
        "tableResult": "task_result",
        "dbHost": "localhost",
        "dbPort": 5432,
        "dbName": "onlyoffice",
        "dbUser": "onlyoffice",
        "dbPass": "onlyoffice",
        "charset": "utf8",
        "connectionlimit": 10,
        "max_allowed_packet": 1048575,
        "pgPoolExtraOptions": {},
        "damengExtraOptions": {}
      },
      "redis": {
        "name": "redis",
        "prefix": "ds:",
        "host": "localhost",
        "port": 6379,
        "options": {},
        "iooptions": {}
      },
      "pubsub": {
        "maxChanges": 1000
      },
      "expire": {
        "saveLock": 60,
        "presence": 300,
        "locks": 604800,
        "changeindex": 86400,
        "lockDoc": 30,
        "message": 86400,
        "lastsave": 604800,
        "forcesave": 604800,
        "saved": 3600,
        "documentsCron": "0 */2 * * * *",
        "files": 86400,
        "filesCron": "00 00 */1 * * *",
        "filesremovedatonce": 100,
        "sessionidle": "1h",
        "sessionabsolute": "30d",
        "sessionclosecommand": "2m",
        "pemStdTTL": "1h",
        "pemCheckPeriod": "10m",
        "updateVersionStatus": "5m",
        "monthUniqueUsers": "1y"
      },
      "ipfilter": {
        "rules": [
          {
            "address": "*",
            "allowed": true
          }
        ],
        "useforrequest": false,
        "errorcode": 403
      },
      "request-filtering-agent": {
        "allowPrivateIPAddress": true,
        "allowMetaIPAddress": false
      },
      "secret": {
        "browser": {
          "string": "secret",
          "file": ""
        },
        "inbox": {
          "string": "secret",
          "file": ""
        },
        "outbox": {
          "string": "secret",
          "file": ""
        },
        "session": {
          "string": "secret",
          "file": ""
        }
      },
      "token": {
        "enable": {
          "browser": false,
          "request": {
            "inbox": false,
            "outbox": false
          }
        },
        "browser": {
          "secretFromInbox": true
        },
        "inbox": {
          "header": "Authorization",
          "prefix": "Bearer ",
          "inBody": false
        },
        "outbox": {
          "header": "Authorization",
          "prefix": "Bearer ",
          "algorithm": "HS256",
          "expires": "5m",
          "inBody": false,
          "urlExclusionRegex": ""
        },
        "session": {
          "algorithm": "HS256",
          "expires": "30d"
        },
        "verifyOptions": {
          "clockTolerance": 60
        }
      },
      "plugins": {
        "uri": "/sdkjs-plugins",
        "autostart": []
      },
      "themes": {
        "uri": "/web-apps/apps/common/main/resources/themes"
      },
      "editor": {
        "spellcheckerUrl": "",
        "reconnection": {
          "attempts": 50,
          "delay": "2s"
        },
        "binaryChanges": false,
        "websocketMaxPayloadSize": "1.5MB",
        "maxChangesSize": "0mb"
      },
      "sockjs": {
        "sockjs_url": "",
        "disable_cors": true,
        "websocket": true
      },
      "socketio": {
        "connection": {
          "path": "/doc/",
          "serveClient": false,
          "pingTimeout": 20000,
          "pingInterval": 25000,
          "maxHttpBufferSize": 100000000
        }
      },
      "callbackBackoffOptions": {
        "retries": 0,
        "timeout": {
          "factor": 2,
          "minTimeout": 1000,
          "maxTimeout": 2147483647,
          "randomize": false
        },
        "httpStatus": "429,500-599"
      }
    }
  },
  "license": {
    "license_file": "",
    "warning_limit_percents": 70,
    "packageType": 0
  },
  "FileConverter": {
    "converter": {
      "maxDownloadBytes": 524288000,
      "maxRequestSize": 524288000,
      "maxFileSize": 524288000,
      "downloadTimeout": {
        "connectionAndInactivity": "10m",
        "wholeCycle": "10m"
      },
      "downloadAttemptMaxCount": 3,
      "downloadAttemptDelay": 1000,
      "maxprocesscount": 1,
      "fontDir": "null",
      "presentationThemesDir": "null",
      "x2tPath": "null",
      "docbuilderPath": "null",
      "args": "",
      "spawnOptions": {},
      "errorfiles": "",
      "streamWriterBufferSize": 8388608,
      "maxRedeliveredCount": 2,
      "inputLimits": [
        {
          "type": "docx;dotx;docm;dotm",
          "zip": {
            "uncompressed": "524288000",
            "template": "*.xml"
          }
        },
        {
          "type": "xlsx;xltx;xlsm;xltm",
          "zip": {
            "uncompressed": "524288000",
            "template": "*.xml"
          }
        },
        {
          "type": "pptx;ppsx;potx;pptm;ppsm;potm",
          "zip": {
            "uncompressed": "524288000",
            "template": "*.xml"
          }
        }
      ],
      "idownloadAttemptMaxCount": 10
    }
  }
}
```



### 1.6 、生成自签名证书

通过命令生成ssl的证书

```bash
# 生成私钥和证书
openssl genrsa -out nginx.key 2048
openssl req -new -key nginx.key -out nginx.csr
openssl x509 -req -in nginx.csr -signkey nginx.key -out nginx.pem
```

## 2、启动服务kodbox的服务

通过docker-compose命令启动kodbox的服务。

```bash
#进入项目目录，执行docker-compose 启动命令，会自动拉取容器并运行
$ docker-compose up -d

#如果需要停止服务
$ docker-compose down
```



