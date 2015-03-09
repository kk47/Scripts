#!/bin/bash


if [ $# != 2 ]; then
    echo "Usage: bash $0 mknodir number "
    exit 1
fi
treedir=/mnt/dayu/$1
num=$2
mknodperf=/root/mknodperf

read -n1 -p "Do you want to create empty file in $treedir (Y/N):" input1
if [[ $input1 == Y || $input1 == y ]];then
    echo -e "\n Start create empty files in dayu ..."
    $mknodperf -t 10 -d $1 -p kkk -f -n $num
fi

read -n1 -p "Do you want to tree $treedir(Y/N):" input2
if [[ $input2 == Y || $input2 == y ]];then
    echo -e "\n Start tree empty files in dayu ..."
    ssh h04 "/usr/bin/tree $treedir &>/dev/null"
    ssh -t h04 "sleep 360;/usr/bin/top -Mn 1 | grep -A 1 PID;source /usr/local/dayu/bin/dayurc &>/dev/null;dayufsmgmt -c GetMemoryStatics"
fi


