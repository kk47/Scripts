#!/bin/bash
# Running clust job from start time to end time in multi ClustNode

function ssh_run
{
    node=$1
    shift
    /usr/bin/ssh $ssh_option root@${node} "$@"
    return $?
}

function check_status
{
    local idx_last=$(echo "$nodenum - 1" | bc)
    for (( i=0; i<$nodenum; i++ )); do
        local node=${nodearr[$i]}
        cmpfile=$dir_tokan/cmplist.$node
        local cmpnum=$(ssh_run $node "[ -f $cmpfile ] && cat $cmpfile |wc -l")
        [[ $cmpnum == "" ]] && cmpnum=0
        if [[ $i -eq $idx_last ]]; then
            splitnum=$(echo "$linenum % $nodenum + $avgnum" | bc)
        else
            splitnum=$avgnum
        fi
        
        echo "+++ $node +++"
        echo "Count:                $splitnum"
        echo "Complete line:        $cmpnum"

        local pid=$(get_pid $node)
        if [ -z "$pid" ]; then
            echo "Staus:                Stop"
            if [[ $cmpnum < $splitnum && $cmpnum > 0 ]]; then
                echo "StopStatu:            Interrupt"
            elif [[ $cmpnum -eq $splitnum ]]; then
                echo "StopStatu:            Complete"
            fi
        else
            echo "Status:               Active"
        fi
    done
}

function set 
{
    # Create tokan dir
    [ -d "$dir_tokan" ] || mkdir -p $dir_tokan

    # Split filelist
    local idx_last=$(echo "$nodenum - 1" | bc)
    for (( i=0; i<$nodenum; i++ )); do
        local fpath="$dir_tokan/filelist.${nodearr[$i]}"
        if [[ $i -eq 0 ]]; then
            local s=1
            local e=`echo "($i + 1) * $avgnum" | bc `
        elif [[ $i -eq $idx_last ]]; then
            local s=`echo "$i * ${avgnum} + 1" | bc`
            local e=${linenum}
        else
            local s=`echo "$i * ${avgnum} + 1" | bc`
            local e=`echo "($i + 1) * $avgnum" | bc `
        fi
        sed -n "$s,${e}p" "$filelist" > "${fpath}"
    done
    
    # Scp the split file list and scripts to  node list
    cp $handle $dir_tokan
    hd_name=`basename $handle`
    handle=$dir_tokan/$hd_name
    for (( i=0; i<$nodenum; i++ )); do
        local node=${nodearr[$i]}
        ssh_run $node "[ -d $dir_tokan ] || /bin/mkdir -p $dir_tokan"
        scp $scp_option "$dir_tokan/filelist.$node" $node:$dir_tokan &>/dev/null
        scp $scp_option "$handle" $node:$dir_tokan &>/dev/null
    done

    # Store config file
    tokanstr="HANDLE=${handle}"
    tokanstr="${tokanstr}\nFILELIST=${filelist}"
    tokanstr="${tokanstr}\nNODELIST=${nodelist}"
    tokanstr="${tokanstr}\nTOKANDIR=${dir_tokan}"
    echo -e "$tokanstr" > $tokanfile
}

function start 
{
    # Start node job and store the command parameters
    if [ ! -f $handle ]; then
        echo "$handle not exist, exit"
        return
    fi
    for (( i=0; i<$nodenum; i++ )); do
        local node=${nodearr[$i]}
        ssh_run $node "nohup bash $nodejob -s $starttime -e $stoptime -t $tokan -j $handle -d $dir_tokan >nohup.out &"
        echo "Start node job at $node : return $?"
    done
}

function stop 
{
    for (( i=0; i<$nodenum; i++ )); do
        local node=${nodearr[$i]}
        local signal="-TERM"
        local pid=$(get_pid $node)
        if [ -z "$pid" ]; then
            echo "Nodejob at $node not running"
        else
            ssh_run $node "kill $signal $pid"
        fi
    done
}

function remove 
{
    # clean environment

    for (( i=0; i<$nodenum; i++ )); do
        local node=${nodearr[$i]}
        local pid=$(get_pid $node)
        if [ -z "$pid" ]; then
            ssh_run $node "rm -fr $dir_tokan"
        else
            echo "Nodejob job $tokan is running"
            return
        fi
    done

    [ -d $dir_tokan ] && rm -fr $dir_tokan
    [ -f $tokanfile ] && rm -f $tokanfile
}

function get_pid
{
    local node=${1?}
    local pid=$(ssh_run $node "ps aux | grep $nodejob " | grep $tokan | awk '{print $2}')
    echo ${pid}
}

function collect
{
    local tmpdir=/tmp/$tokan.result
    [ -d $tmpdir ] || mkdir $tmpdir
    for (( i=0; i<$nodenum; i++ )); do
        local node=${nodearr[$i]}
        scp $scp_option $node:$dir_tokan/reslist.$node $tmpdir &>/dev/null
        scp $scp_option $node:$dir_tokan/cmplist.$node $tmpdir &>/dev/null
        scp $scp_option $node:$dir_tokan/faillist.$node $tmpdir &>/dev/null
    done
    local now=$(date +%F_%H:%M)
    local tgzpath=$dir_tokan/result-$now.tgz
    tar -czf $tgzpath $tmpdir &>/dev/null
    [ -d $tmpdir ] && rm -fr $tmpdir
}

function load_cfg
{
    OLDIFS=$IFS
    IFS="="
    while read key value; do
        if [[ "$key" == "" || "$value" == "" || "$key" == "#" ]]; then
            continue
        fi
        
        if [[ "$key" == "HANDLE" ]]; then
            handle=$value
        elif [[ "$key" == "FILELIST" ]]; then
            filelist=$value
        elif [[ "$key" == "TOKANDIR" ]]; then
            dir_tokan=$value
        fi
    done < $1
    IFS=$OLDIFS
}

function prepareEnv
{
    # Prepare environment
    dir_tokan=$rundir/$tokan

    # Parse the nodelist file
    if [ ! -f $nodelist ]; then
        echo "$nodelist not exist,exit"
        exit 1
    fi
    nodestr=""
    while read node ; do
        nodestr="$nodestr $node"
    done<$nodelist

    nodearr=($nodestr)
    nodenum=${#nodearr[*]}
    if [ $nodenum -eq 0 ]; then
        echo "Nodelist file is empty"
    fi

    linenum=$(wc -l $filelist | awk '{print $1}')
    avgnum=$(echo "$linenum / $nodenum" | bc)

    # Create dir and tokan file in control node
    [ -d "$configdir" ] || mkdir -p $configdir
    tokanfile=$configdir/$tokan
    
}

function usage 
{
    echo "Usage:bash `basename $0` -j handlescript -l nodelist -f filelist -s starttime -e endtime -d rundir -c cmd"
    echo "      -h help message"
    echo "      -j path to handle script"
    echo "      -l node list to run clust job"
    echo "      -f full filelist"
    echo "      -s start time format as 0612 means 06:12 am"
    echo "      -e end time format as 0612 means 06:12 am"
    echo "      -d work directory of clust job"
    echo "      -c comand to run "
    echo "          set         set environment"
    echo "          start       start clust job"
    echo "          stop        stop clust job"
    echo "          remove      remove work dirs"
    echo "          result      collect result"
    echo "          status      show status"
    exit 0
}

handle=""
nodelist=/root/clustjob/nodelist
filelist=/root/clustjob/filelist
starttime=""
stoptime=""
nodejob=/usr/local/dayu/scripts/nodejob.sh
ssh_option="-o User=root -o StrictHostKeyChecking=no"
scp_option="-o User=root -o StrictHostKeyChecking=no"
configdir=/var/local/dayu/clustjob/control
rundir=/var/local/dayu/clustjob

while getopts 'j:l:f:s:e:c:d:t:h' OPT; do
    case $OPT in
        j)
            handle=$OPTARG;;
        l)
            nodelist=$OPTARG;;
        f)
            filelist=$OPTARG;;
        s)
            starttime=$OPTARG;;
        e)
            stoptime=$OPTARG;;
        c)
            cmd=$OPTARG;;
        d)
            nodejobdir=$OPTARG;;
        t)
            tokan=$OPTARG;;
        h)
            usage;;
        ?)
            usage;;
    esac
done

if [[ -z $cmd ]]; then
    echo "option -c has not been set,exit"
    exit 1
fi

if [ "$cmd" == "set" ]; then
    if [[ -z $handle || -z $filelist ]]; then
        echo "filelist or nodelist or handle script not exist"
        exit 1
    fi
    ran=$RANDOM
    pid=$$
    tokan=${ran}-${pid}
else
    if [ -z $tokan ]; then
        echo "Please set tokan value"
        exit 1
    fi

    if [ ! -f $configdir/$tokan ]; then
        echo "Config file not exist,exit"
        exit 1
    fi
    load_cfg $configdir/$tokan
fi

prepareEnv

# Handle different command
case $cmd in
    status)
        check_status;;
    set)
        echo "Tokan is : $tokan"
        set;;
    start)
        start;;
    result)
        collect;;
    remove)
        remove;;
    stop)
        stop;;
    *)
        usage;;
esac
