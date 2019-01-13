#!/bin/bash

yum -y install docker git vim-enhanced && systemctl enable docker && \
dd if=/dev/zero of=/swapfile bs=1024 count=1048576 && mkswap /swapfile && chmod 600 /swapfile && swapon /swapfile && \
cd /var/lib && mv docker /mnt/volume_*/ && ln -s /mnt/volume_*/docker && systemctl start docker && cd ~
git clone https://github.com/XelaNull/docker-c7.git && \
git clone https://github.com/XelaNull/docker-c7-rtorrent-flood.git && \
cd docker-c7 && docker build -t c7/lamp . && cd ../docker-c7-rtorrent-flood && \
docker build -t c7/rtorrent-flood . && docker run -dt -p8080:80 -p3000:3000 -p50000:50000 --name=rtorrent-flood c7/rtorrent-flood

