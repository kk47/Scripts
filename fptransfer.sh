#!/bin/bash
#  check,create,chown,chmod,and mv file when transfer source dir to destination dir


if [[ $# != 1 ]] ; then
    echo "Usage:bash $0 listfile"
    exit 1
else
    read -n1 -p "Moving files in $1 (Y/N):" input
    case $input in
        Y|y) 
            echo -e "\n OK!";;
        N|n) 
            echo -e "\nExit";
            exit 1;;
        *)  
            echo -e "\nIncorrect input";
            exit 2;;
        esac
fi

logfile=./transfer.log
mvuser=imgo
mvgroup=imgo
filelist=$1

if [[ ! -f $filelist ]] ; then
    echo "Filelist not exists "
    exit 1
else
    id $mvuser &> /dev/null
    if [[ $? -ne 0 ]] ; then
        echo "User $mvuser not exists"
        exit 1
    fi
fi

[ -e $logfile ] && echo > $logfile

date >> $logfile
cat "$filelist" | while read sourcefilename destfilename
do
    destfiledir=`dirname "$destfilename"`
    
    
    if [[ ! -d "$destfiledir" ]] ; then
        mkdir -p "$destfiledir"
        if [[ $? -ne 0 ]]; then
            echo "Failed to mkdir $destfiledir"
            exit 1
        fi
        chown ${mvuser}:${mvgroup} "$destfiledir"
        if [[ $? -ne 0 ]]; then
            echo "Failed to chown for $destfiledir"
            exit 1
        fi
    fi

    if [[ -e "$sourcefilename" ]] ; then
        mv "$sourcefilename" "$destfilename"
        if [[ $? -ne 0 ]]; then
            echo "Failed to mv from $sourcefilename to $destfilename"
            exit 1
        fi
        chown ${mvuser}:${mvgroup} "$destfilename"
        if [[ $? -ne 0 ]]; then
            echo "Failed to chown for $destfilename"
            exit 1
        fi
        echo "$sourcefilename moved"
    else
        echo "$sourcefilename not exists"
        exit 1
    fi

done &>>$logfile

date >> $logfile
