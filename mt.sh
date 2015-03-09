#!/bin/bash
# wrap the multithread tool

if [ $# != 2 ]; then
    echo "Usage: bash `basename $0` thread-number http-path-prefix"
    echo "example: bash mt.sh 200 videos/dir(dir1~dir100)"
    exit 0
fi

tnum=$1
path=$2
mpah=/root/multithread
fname=/root/ulist-$tnum
http=http://10.0.0.44
n=`expr $tnum / 100`
m=`expr $tnum % 100`
p=`expr $n + 1`
q=`expr $n + $m`

# create config files
for i in `seq 1 100`; do
    for j in `seq 1 $n`; do
        tname=test$j.mp4
        echo "$http/${path}${i}/$tname" >> $fname
    done
done

for k in `seq $p $q`; do
    tname=test$k.mp4
    echo "$http/$path/$tname" >> $fname
done

# execute multithread test
$mpath $fname











