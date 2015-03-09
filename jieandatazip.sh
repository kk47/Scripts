#!/bin/bash
#zip the jieandata

function Zipdata
{
    if [ -s "$ziplist" ] ;then
        cd $zipdir
        for dir in `cat "$ziplist"`
        do
            sname=$(basename "$dir")
            tname=$(basename "$dir.tar.bz2")
            if [ ! -f "$targetdir/$tname" ] ;then
                tar -cjf "$targetdir/$tname" "$sname"
                if [ -f "$targetdir/$tname" ] ;then
                    #echo "$dir"|grep "$zipdir/20" && rm -rf "$dir"
                    echo "$dir done" &> $logdir
                fi  
            else
                echo "[`date +%F-%T`]:$dir.tar.bz2 already existed." &>> $logdir 
            fi
        done
    fi
}

logdir=/var/log/dayu/ziplog
ziplist=/var/log/dayu/ziplist
zipdir=/mnt/dayu/jieandata
targetdir=/mnt/dayu/jieanzipdata

[ -d $targetdir ] || mkdir $targetdir

#find $zipdir -mindepth 1 -maxdepth 1 -type d -mtime +180 -size +0 1> $ziplist
find $zipdir -mindepth 1 -maxdepth 1 -type d -size +0 1> $ziplist

Zipdata


