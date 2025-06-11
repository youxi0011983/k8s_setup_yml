docker run  -d \
     --name wyl \
	-e "TZ=Asia/Shanghai" \
	-e GUIIP=192.168.0.126 \
    -e GUIPORT=8850 \
    -e IFACE=ens33  \
    -e THEME=darkly  \
    --network="host" \
	-v /tmp/watchyourlan/wyl:/data \
    aceberg/watchyourlan