# 生成私钥和证书
openssl genrsa -out nginx.key 2048
openssl req -new -key nginx.key -out nginx.csr
openssl x509 -req -in nginx.csr -signkey nginx.key -out nginx.pem