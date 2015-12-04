#!/bin/bash
# use iozone to do disk perf test

disk=(a b c d e f g h i j k l m n o p q r s t u v w x)

function ddParallelPerf
{
    echo -n "Start to do disk write perf ... "
    for i in ${disk[@]}; do
        #(dd if=/dev/zero of=/dev/sd$i bs=4M count=40960 >> /root/dd-all-write.log) &
        (sleep 60) &
        echo "(dd if=/dev/zero of=/dev/sd$i bs=4M count=40960 >> /root/dd-all-write.log) &"
    done
    wait
    echo "Done"
    echo -n "Start to do disk read perf ... "
    for i in ${disk[@]}; do
        #(dd if=/dev/sd$i of=/dev/null bs=4M count=40960 >> /root/dd-all-read.log) &
        (sleep 60) &
        echo "(dd if=/dev/sd$i of=/dev/null bs=4M count=40960 >> /root/dd-all-read.log) &"
    done
    wait
    echo "Done"
}

function iozoneParallelPerf
{
    for i in ${disk[@]}; do
        #(mkfs.ext4 /dev/sd$i -m 0 -p) &
        echo "(mkfs.ext4 /dev/sd$i -m 0 -p) &"
    done
    wait
    for i in ${disk[@]}; do
        #[ -d /tmp/sd$i ] || mkdir /tmp/sd$i
        echo "mount /dev/sd$i /tmp/sd$i || echo "mount sd$i failed""
        #mount /dev/sd$i /tmp/sd$i || echo "mount sd$i failed"
    done
    
    ipath=`which iozone`
    [ $? -ne 0 ] && echo "not iozone tool found" && exit 1 
    for i in ${disk[@]}; do
        #($ipath -a -ec -i 0 -i 1 -n 2g -g 16g -r 1m -f /mnt/sd$i >> /root/iozone-all.log) &
        echo "($ipath -a -ec -i 0 -i 1 -n 2g -g 16g -r 1m -f /mnt/sd$i >> /root/iozone-all.log) &"
    done
    
}

function usage
{
    cat << EOF
Example:
    `basename $0` -c dd
Parameter:
    -c cmd dd or iozone
    -h help
EOF
    exit 0
}

while getopts 'hc:b:s:' OPT; do
    case $OPT in
        c)
            cmd=$OPTARG;;
        b)
            bsize=$OPTARG;;
        s)
            fsize=$OPTARG;;
        h)
            usage;;
        ?)
            usage;;
    esac
done 

if [[ -z $cmd ]]; then
    echo "please set command(-c)"
    exit 1
fi

echo -n "Are you sure to do disk perf, this will clean all you data of disk /dev/sd[a-x]
make sure there is no important data in these disk(Yes\No):"
read ans
if [[ "$ans" != "Yes" && "$ans" != "yes" ]]; then
    echo "disk perf canceled"
    exit 0
fi

case $cmd in
    dd)
        ddParallelPerf;;
    iozone)
        iozoneParallelPerf;;
    ?)
        echo "unknow command"
        exit 1;;
esac
