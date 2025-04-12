# 产创建专用网络
docker network create -d macvlan --subnet=192.168.2.0/24 --gateway=192.168.2.1 -o enp1s0 macnet

# 启动arm的版本的openwrt
docker run --restart always --name openwrt -d --network macnet --privileged sulinggg/openwrt:armv8 /sbin/init

# 启动arm的版本的openwrt
docker run --restart always --name openwrt -d --network macnet --privileged piaoyizy/openwrt-x86:latest /sbin/init