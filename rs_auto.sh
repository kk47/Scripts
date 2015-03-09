#!/bin/bash
# rsync local dir to remote rsync server

function check_rsync
{
    ps aux | grep -v grep | grep rsync 
    if [[ $? -eq 0 ]]; then
        echo "rsync is running now."
        exit 1
    fi
}

function sync_connect
{
    check_rsync
    if [[ $? -ne 0 ]]; then
        rsync -arvu $sourcedir rsync://$dest
        if [[ $? -ne 0 ]]; then
            echo "[ERROR]:$(date),rsync $sourcedir to $dest failed"
        else
            echo "[INFO]:$(date),rsync $sourcedir to $dest succeed"
        fi
    fi
}

if [[ $# != 2 ]];then
    echo "Usage: `basename $0` /tmp/test/ 192.168.174.211/share/"
    exit 1
fi

sourcedir=$1
dest=$2
sync_connect
