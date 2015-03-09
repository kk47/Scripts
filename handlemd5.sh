#!/bin/bash
# calculate md5sum from a list of file and store the result

function dayumd5sum {
    local fname="$mntpnt/$1"
    if [[ ! -f "$fname" ]];then
        echo "$fname not exist." >>$logfile
        return 2
    fi
    local sum=$(md5sum "$fname")
    if [[ $? -eq 0 ]];then
        sum=$(echo "$sum" | awk '{print $1}')
        echo "$sum $1" >> $reslist
        return 0
    else
        return 1
    fi
}

function usage {
    echo "Usage:bash `basename $0` -f /dayupath/file -o ./filelist.md5"
    echo "      -f file path to do md5sum"
    echo "      -o result file of md5sum"
    exit 2
}

mntpnt=/mnt/dayu
logfile=./md5sumlog

while getopts 'f:o:h' OPT; do
    case $OPT in
        f)
            filename=$OPTARG;;
        o)
            reslist=$OPTARG;;
        h)
            usage;;
    esac
done
    
dayumd5sum ${filename}
exit $?
