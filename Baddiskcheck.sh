#!/bin/bash

function dsmgmt_check()
{
    echo -e "\033[1;33mDayu ds ErrorCount check:\033[0m"
    dayudsmgmt -c GetStatics |grep -v Failed | grep -i ErrorCount
    if [[ $? -eq 0 ]];then
        echo -e "\033[1;33mFAILED\033[0m"
    else
        echo -e "\033[1;32mPASS\033[0m"
    fi
}

function smartctl_self_check()
{
    echo -e "\033[1;33m\nSmartctl self-test:\033[0m"
    for disk in ${disklist[@]};do
        smartctl -H $disk | grep "PASSED" &>/dev/null
        echo -n "$disk:"
        if [[ $? -ne 0 ]];then
            echo -e "\033[1;33mFAILED\033[0m"
        else
            echo -e "\033[1;32mPASS\033[0m"
        fi
    done
}

function smartctl_para_check()
{
    drive=$1
    bn=`basename $1`
    slog=/tmp/smartctl-a-$bn
    smartctl -a $drive &> $slog
    value="$1     "
    for p in ${para[@]};do
        tvalue=$(grep -i $p $slog | xargs |cut -d " " -f10)
        if [[ $tvalue == "" ]];then
            tvalue="-"
        fi
        value="$value         $tvalue         "
    done
    echo "$value"
}

disklist=(`ls /dev/[sh]d* | tr -d "[0-9]+$" | uniq`)
p1="Reallocated_Sector_Ct"
p2="Command_Timeout"
p3="Current_Pending_Sector"
p4="Reallocated_Event_Count"
p5="Offline_Uncorrectable"
para=( $p1 $p2 $p3 $p4 $p5 )
dsmgmt_check
smartctl_self_check
echo -e "\033[1;33m\nSmartctl key parameter:\033[0m"
echo -e "\033[1;33m\ndrive    ${para[@]}\033[0m"
for d in ${disklist[@]};do
    smartctl_para_check $d
done

