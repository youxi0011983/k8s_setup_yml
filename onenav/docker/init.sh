docker run -d --name="onenav" \
        --restart always \
        -p 8011:80  \
        -e USER='admin' \
        -e PASSWORD='admin'  \
        -v /data/onenav/data:/data/wwwroot/default/data  \
        helloz/onenav:0.9.29