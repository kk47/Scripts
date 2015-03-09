#!/bin/bash
#install nload
#Time:2013-10-18

cp /mnt/source/dayu/tools/nload-0.7.4.tar.gz /mnt/sysimage/tmp
[ -f /mnt/sysimage/tmp/nload-0.7.4.tar.gz ] && tar -xvf /mnt/sysimage/tmp/nload-0.7.4.tar.gz -C /mnt/sysimage/tmp || exit 1
cd /mnt/sysimage/tmp/nload-0.7.4
./configure && make && make install
