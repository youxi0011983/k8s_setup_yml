# 文档预览服务器
docker run -d -it -p 8012:8012  keking/kkfileview

docker run -d -it -p 8012:8012 \
  -v /opt/kkFileView/config:/opt/kkFileView-4.1.0/config \
  -v /opt/kkFileView/file:/opt/kkFileView-4.1.0/file \
  keking/kkfileview

# http://192.168.0.126:8080/hosting/discovery