FROM nginx:latest
# 安装 ModSecurity 依赖项
RUN apt-get update && apt-get install -y libmodsecurity3
# 复制 ModSecurity 配置文件
COPY modsecurity.conf /etc/nginx/modsecurity.conf
# 复制 Nginx 配置文件
COPY nginx.conf /etc/nginx/nginx.conf
# 复制 CRS 规则文件
COPY crs-30305.xml /usr/local/apache2/conf/modsecurity/base_rules/crs-30305.xml
# 复制自定义规则文件（如果有）
COPY custom_rules.conf /etc/nginx/custom_rules.conf
# 暴露端口
EXPOSE 80
