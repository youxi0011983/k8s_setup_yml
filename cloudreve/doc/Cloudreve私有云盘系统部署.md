# Cloudreve 私有云盘系统部署



### **一、Cloudreve 部署**

#### **1. Linux 系统部署**

##### **方法 1：使用 Docker 部署**

1. **安装 Docker**

   如果尚未安装 Docker，请参考官方文档安装：https://docs.docker.com/engine/install/。

2. **拉取 Cloudreve 镜像**

   ```bash
   docker pull cloudreve/cloudreve
   ```

   

3. **运行 Cloudreve 容器**

   以下命令会创建一个名为 `cloudreve` 的容器，将容器的 `5212` 端口映射到宿主机的 `5212` 端口，并挂载配置文件和上传目录：

   ```bash
   docker run -d \
     --name cloudreve \
     -p 5212:5212 \
     -v /path/to/config:/config \
     -v /path/to/uploads:/cloudreve/uploads \
     cloudreve/cloudreve
   ```

   - `/path/to/config`：宿主机的配置文件目录（如 `/home/user/cloudreve/config`）。
   - `/path/to/uploads`：宿主机的上传文件存储目录（建议选择大容量磁盘）。

4. **初始化配置**

   首次运行后，通过浏览器访问 `http://服务器IP:5212`，完成初始化配置：

   - 设置管理员账号和密码。
   - 选择数据库类型（推荐 SQLite，默认配置即可）。
   - 配置站点信息（可选）。

5. **查看日志获取初始密码**

   如果未及时保存初始密码，可以通过以下命令查看日志：

   ```bash
   docker logs cloudreve
   ```

   密码通常出现在类似 `Initial admin account: username, password` 的日志中。

##### **方法 2：手动部署（非 Docker）**

1. **下载 Cloudreve**

   从 GitHub 下载对应版本的安装包：

   ```bash
   wget https://github.com/cloudreve/Cloudreve/releases/download/v3.8.3/cloudreve_3.8.3_linux_amd64.tar.gz
   ```

   

2. **解压并赋予执行权限**

   ```bash
   tar -zxvf cloudreve_3.8.3_linux_amd64.tar.gz
   chmod +x ./cloudreve
   ```

3. **启动 Cloudreve**

   ```bash
   ./cloudreve
   ```

   首次启动会生成默认配置文件 `conf.ini` 和数据库文件 `cloudreve.db`。

4. **开放防火墙端口**

   确保服务器防火墙允许 `5212` 端口访问：

   ```bash
   sudo ufw allow 5212/tcp
   sudo ufw reload
   ```

   

5. **设置开机自启（可选）**

   创建 systemd 服务文件：

   ```bash
   sudo nano /etc/systemd/system/cloudreve.service
   ```

   内容如下：

   ```bash
   [Unit]
   Description=Cloudreve
   After=network.target
   
   [Service]
   ExecStart=/path/to/cloudreve
   WorkingDirectory=/path/to/cloudreve
   Restart=always
   User=nobody
   
   [Install]
   WantedBy=multi-user.target
   ```

   启用并启动服务

   ```bash
   sudo systemctl enable cloudreve
   sudo systemctl start cloudreve
   ```



#### **2. Windows 系统部署**

##### **方法 1：使用 Docker 部署**

1. **安装 Docker Desktop**

   下载并安装 Docker Desktop：https://www.docker.com/products/docker-desktop/。

2. **拉取 Cloudreve 镜像**

   ```bash
   docker pull cloudreve/cloudreve
   ```

   

3. **运行 Cloudreve 容器**

   ```bash
   docker run -d `
     --name cloudreve `
     -p 5212:5212 `
     -v C:/cloudreve/config:/config `
     -v C:/cloudreve/uploads:/cloudreve/uploads `
     cloudreve/cloudreve
   ```

   

4. **初始化配置**

   访问 `http://localhost:5212` 完成初始化配置。

##### **方法 2：手动部署（非 Docker）**

1. **下载 Cloudreve**

   从 GitHub 下载 Windows 版本的安装包：

   ```bash
   Invoke-WebRequest -Uri "https://github.com/cloudreve/Cloudreve/releases/download/v3.8.3/cloudreve_3.8.3_windows_amd64.zip" -OutFile "cloudreve.zip"
   ```

   

2. **解压并运行**

   解压后直接运行 `cloudreve.exe`，首次启动会生成配置文件和数据库。

3. **开放防火墙端口**

   在 Windows 防火墙中允许 `5212` 端口入站规则。

### **二、Cloudreve 基本操作**

#### **1. 初始化配置**

- 管理员账号：首次访问时设置，密码仅首次启动时生成，需妥善保存。
- 数据库选择：推荐使用 SQLite（无需额外配置），高级用户可切换为 MySQL/PostgreSQL。
- 存储路径：默认存储路径为 /cloudreve/uploads（Linux）或 C:\cloudreve\uploads（Windows），可通过配置文件修改。

#### **2. 配置文件修改**

- **配置文件路径**：

  - Docker 模式：`/path/to/config/conf.ini`
  - 非 Docker 模式：`./conf.ini`

- **常用配置项**：

  ```bash
  [database]
  type = sqlite
  name = cloudreve.db
  user =
  password =
  host =
  port =
  ```

  - 修改监听端口：

    ```bash
    server]
    listen = :80
    ```

    

  - 启用 HTTPS（需配置 SSL 证书）：

    ```bash
    [server]
    https = true
    certFile = /path/to/cert.pem
    keyFile = /path/to/privkey.pem
    ```



#### **3. 远程访问配置**

##### **方法 1：内网穿透（无公网 IP）**

- 使用 **Cpolar** 或 **frp** 等工具创建隧道：

  ```bash
  # Cpolar 示例（需注册并获取 token）
  ./cpolar auth <token>
  ./cpolar http 5212
  ```

  访问生成的公网地址即可远程访问。

##### **方法 2：公网 IP 配置**

1. **路由器端口转发**

   将路由器的 `5212` 端口转发到 Cloudreve 服务器的 IP 地址。

2. **域名绑定（可选）**

   使用域名访问时，需在路由器或服务器上配置反向代理（如 Nginx）：

   ```bash
   server {
       listen 80;
       server_name yourdomain.com;
   
       location / {
           proxy_pass http://127.0.0.1:5212;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
       }
   }
   ```

   

#### **4. 常见功能使用**

- **文件上传与下载**

  登录后，直接拖拽文件到界面或点击“上传”按钮。支持批量上传和文件夹上传。

- **分享链接**

  右键文件或文件夹，选择“创建分享链接”，可设置密码、过期时间等。

- **离线下载（Aria2 支持）**

  1. 安装 Aria2 并配置。

  2. 在 Cloudreve 的管理面板中启用 Aria2 驱动，填写 Aria2 的 RPC 地址和密钥。

- **用户管理**

  在管理面板中添加用户、分配存储空间，并设置用户组权限。



### **三、常见问题**

#### **1. 忘记管理员密码**

- Docker 模式：删除容器中的 cloudreve.db 文件，重新启动容器以初始化数据库。

  ```bash
  docker exec -it cloudreve rm /config/cloudreve.db
  docker restart cloudreve
  ```

- 非 Docker 模式：删除 cloudreve.db 文件后重新运行 Cloudreve。

#### **2. 端口冲突**

- 修改配置文件中的 `listen` 参数，或通过防火墙规则调整端口映射。

#### **3. 存储空间不足**

- 修改上传目录路径到更大容量的磁盘：

  ```bash
  [storage]
  path = /mnt/bigdisk/cloudreve/uploads
  ```



### **四、总结**

Cloudreve 是一款功能强大且易于部署的私有云盘系统，支持多种部署方式（Docker/手动安装）和灵活的配置选项。通过上述步骤，您可以在 Linux 或 Windows 系统中快速搭建一个私有云存储环境，并通过内网穿透或公网 IP 实现远程访问。