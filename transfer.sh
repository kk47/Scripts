#!/bin/bash
#  check,create,chown,chmod,and mv file when transfer source dir to destination dir


if [[ $# != 2 ]] ; then
    echo "Usage:bash $0 sourcedir destinationdir"
    exit 1
else
    read -n1 -p "Confirm:move file from $1 to $2(Y/N):" input
    case $input in
        Y|y) 
            echo -e "\n OK!";;
        N|n) 
            echo -e "\nExit";
            exit 1;;
        *)  
            echo -e "\nerror choice";
            exit 2;;
        esac
fi

sourcedir=`echo "$1" |sed 's/\/$//'`
destdir=`echo "$2" |sed 's/\/$//'`
logfile=/tmp/dayu/transfer.log
filelist=/root/mvlists.txt
mvuser=mvtest
mvgroup=mvtest

if [[ ! -f $filelist ]] ; then
    echo "no filelist exists "
    exit 1
else
    id $mvuser &> /dev/null
    if [[ $? -ne 0 ]] ; then
        echo "User $mvuser not exists"
        exit 1
    fi
fi

[ -d /tmp/dayu/ ] || mkdir /tmp/dayu/ 
[ -e $logfile ] && echo > $logfile

date >> $logfile
cat $filelist | while read sourcefile destfile 
do
    sourcefilename="$sourcedir/$sourcefile"
    destfilename="$destdir/$destfile"
    destfiledir=`dirname "$destfilename"`
    
    
    if [[ ! -d "$destfiledir" ]] ; then
        mkdir -p "$destfiledir"
        chown mvtest:mvtest "$destfiledir"
        #echo "mkdir -p "$destfiledir""
        #echo "chown mvtest:mvtest "$destfiledir""
    fi

    if [[ -e "$sourcefilename" ]] ; then
        mv "$sourcefilename" "$destfilename"
        chown mvtest:mvtest "$destfilename"
        #echo "mv "$sourcefilename" "$destfilename""
        #echo "chown mvtest:mvtest "$destfilename""

        #chmod -R 755 "$destfilename"
        echo "$destfilename mv done"
    else
        echo "$sourcefilename not exists"
    fi

done &>>$logfile

date >> $logfile
