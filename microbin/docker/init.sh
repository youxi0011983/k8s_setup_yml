docker run -d \
   --restart always  \
   --name microbin \
   -p 6300:8080 \
   -v /data/microbin/data:/app/microbin_data \
   -e MICROBIN_ADMIN_USERNAME=jeven \
   -e MICROBIN_ADMIN_PASSWORD=admin  \
   -e MICROBIN_ENABLE_BURN_AFTER=true \
   danielszabo99/microbin:latest