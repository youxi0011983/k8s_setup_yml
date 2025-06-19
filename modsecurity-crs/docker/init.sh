docker run --name Nginx-WAFProxy -v /web/NginxProxy/nginx.conf.template:/etc/nginx/templates/nginx.conf.template:rw  -d owasp/modsecurity-crs:nginx

