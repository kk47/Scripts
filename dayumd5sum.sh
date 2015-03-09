#!/bin/bash
# calculate md5sum from a list of file and store the result

function dayumd5sum {
    local fname="$mntpnt/$1"
    if [[ ! -e "$fname" ]];then
        echo "$fname not exist." >>$logfile
    fi
    sum=$(md5sum "$fname"|awk '{print $1}')
    if [[ $? -eq 0 ]];then
        echo "$sum $1" >> $mlist
    else
        echo "$fname" >> $errlist
        echo "$fname md5sum failed." >>$logfile
    fi
}

function usage {
    echo "Usage:bash `basename $0` -s ./filelist -m  ./filelist.md5"
    echo "      -s source file list to do md5sum"
    echo "      -m result file of md5sum"
    exit 0
}

mlist=./mlist
errlist=./errlist
mntpnt=/root
logfile=./md5sumlog

while getopts 's:m:h' OPT; do
    case $OPT in
        s)
            slist=$OPTARG;;
        m)
            mlist=$OPTARG;;
        h)
            usage;;
    esac
done

if [[ ! -f $slist ]];then
    usage
fi
echo "$(date) start md5sum" >>$logfile
now=`date +%H`
deadtime=18

[ -f $mlist ] && mv $mlist "$mlist.$now"
[ -f $errlist ] && mv $errlist "$errlist.$now"

while read file
do
    if [[ $now > $deadtime ]];then
        echo "Time is up, end md5sum!" >>$logfile
        exit 1
    fi
    dayumd5sum "$file"
done<$slist
