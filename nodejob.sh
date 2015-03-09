#!/bin/bash
# Running with clustjob.sh
# Control when will the handle.sh start and stop

function noderun
{
    handlerun=false
    get_fpos
    if [ $? -ne 0 ]; then
        return $?
    fi
    while read file ; do
        # Time check and wait
        now=`date +%H%M`
        if [[ $now < $starttime ]]; then
            sleeps=$(time_diff $now $starttime)
            echo "Not running time yet, sleep $sleeps second" >> $logfile
            sleep $sleeps
        elif [[ $now > $stoptime ]]; then
            sleeps=$(time_diff $now $starttime)
            echo "Time is up, end $handle, sleep $sleeps second" >> $logfile
            sleep $sleeps
        fi

        # Second time running nodejob script handle
        if [[ $handlerun == "false" ]]; then
            if [[ "$file" != "$beginfile" ]]; then
                continue
            fi
        fi
        handlerun=true

        $handle -f "$file" -o "$respath"
        if [ $? -ne 0 ]; then
            echo "$file" >> $failpath
        fi
        echo "$file" >> $cmppath
    done<$filepath
}

function get_fpos
{
    if [[ ! -f $cmppath ]]; then
        echo "Function get_fpos: $cmppath not exist, create it and start nodejob"
        touch $cmppath
        beginfile=$(head -n 1 $filepath)
        return 0
    fi

    filecount=$(wc -l $filepath | awk '{print $1}')
    cmpcount=$(wc -l $cmppath | awk '{print $1}')
    cmplast=$(tail -n 1 $cmppath)
    filelast=$(tail -n 1 $filepath)
    
    if [[ $cmpcount -eq 0 ]]; then
        beginfile=$(head -n 1 $filepath)
    else
        if [[ "$cmplast" == "$filelast" ]]; then
            echo "Function get_fpos: nodejob complete"
            return 1
        else
            grep "$cmplast" $filepath &>/dev/null
            if [[ $? -ne 0 ]]; then
                echo "Function get_fpos: new filelist exist"
                beginfile=$(head -n 1 $filepath)
            else
                echo "running nodejob.sh second time"
                beginfile=$(tail -n 1 $cmppath)
            fi
        fi
    fi
    return 0
}

function time_diff
{
    t1=$1
    t2=$2
    if [[ "${t1}" < "${t2}" ]]; then
        diff_h=$(echo "(${t2} - ${t1}) / 100" | bc)
        diff_m=$(echo "(${t2} - ${t1}) % 100" | bc)
    else
        diff_h=$(echo "23 - ((${t2} - ${t1}) / 100)" | bc)
        diff_m=$(echo "59 - ((${t2} - ${t1}) % 100)" | bc)
    fi
    diff_s=$(echo "$diff_h * 3600 + $diff_m * 60" | bc)
    echo "$diff_s"
}

function usage
{
    echo "Usage:bash `basename $0` -s starttime -e stoptime -j handle -t tokan"
    echo "      -h help message"
    echo "      -s start time"
    echo "      -e stop time"
    echo "      -j handle script "
    echo "      -t tokan flag"
    exit 0
}


while getopts 's:e:j:t:d:h' OPT ; do
    case $OPT in
        s)
            starttime=$OPTARG;;
        e)
            stoptime=$OPTARG;;
        j)
            handle=$OPTARG;;
        t)
            tokan=$OPTARG;;
        d)
            dir_tokan=$OPTARG;;
        h)
            usage;;
        *)
            usage;;
    esac
done

if [[ ! -f $handle ]]; then
    echo "$handle not exist,exit"
    exit 1
fi

if [[ ! -d $dir_tokan ]]; then
    echo "dir_tokan is not exist"
    exit 1
fi

logfile=$dir_tokan/nodejob.log
filepath=$dir_tokan/filelist.$HOSTNAME
respath=$dir_tokan/reslist.$HOSTNAME
cmppath=$dir_tokan/cmplist.$HOSTNAME
failpath=$dir_tokan/faillist.$HOSTNAME

if [[ ! -f $dir_tokan/filelist.$HOSTNAME ]]; then
    echo "filelist.$HOSTNAME not exist,exit"
    exit 1
fi

noderun
exit $?
