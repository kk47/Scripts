#!/bin/bash
#copy the chunk which replia is 1
# file chklist is the list of chunk 
# file downlist is the list of chunk file which checked
# file cplist is the list of chunk file which need copy

function check
{
    find /dayudata/ds -type f|grep -v .uuid > chunklist
    cat /dev/null > cplist
    for chk in `cat chunklist`
    do
        local id=`echo $chk |awk -F"/" '{print $6}'`
        [ -f downlist ] && grep $chk downlist &>/dev/null
        if [ $? -eq 0 ]
        then
            
            echo "$id already down"
        else
            dayumdsmgmt -c GetChunkStatus -p chunkId=$id|grep "chunkLevel=1" &>/dev/null
            if [ $? -eq 0 ] 
            then
                echo $chk >> cplist
            else
                echo $chk >> downlist
            fi
        fi
    done
}

function copy
{
    z=`ls -l cplist |awk '{print $5}'`
    declare -i i=0
    declare -i n=${#uuid[@]}
    n=$n-1
    for file in `cat cplist`
    do
        [ $z -eq 0 ] && break
        did=`echo $file|awk -F"/" '{print $5}'`
        local id=`echo $file |awk -F"/" '{print $6}'`
        ssh -n $host ls /dayudata/ds/${uuid[$i]}/$did/$id &>/dev/null && echo "/${uuid[$i]}/$did/$id exist,overrite!" 
        scp $file $host:/dayudata/ds/${uuid[$i]}/$did/
        [ $? -eq 0 ] && echo "$id copy ok" && echo $file >>downlist 
        [ $i -lt $n ] && i=$i+1 || i=0
    done
}

#judge the input parm
if [ $# -ne 1 ];
then
    echo "Usage  $0 d29 (Attention the host!) " 
    exit 1 
fi
read -n1 -p "Are you sure to copy chunk (Y/N):" input
case $input in
    Y|y)
        echo -e "\n Copy chunk starting ... ...";;
    N|n)
        echo -e "\nExit";
        exit 1;;
    *)      
        echo -e "\nerror choice";
        exit 1;;
esac

#get dest host and dest disk uuid
host=$1
uuid=(`ssh $host "ls /dayudata/ds"`)

#The first time check
echo  -e "\033[1;33m\n$(date +%F-%H:%M:%S) First check begin ...\n##########################\033[0m" | tee -a /tmp/copy.log
check && echo "Time `date +%F-%H:%M:%S` first check...down" |tee -a /tmp/copy.log
echo  -e "\033[1;33m\n$(date +%F-%H:%M:%S) First copy begin ...\n##########################\033[0m" | tee -a /tmp/copy.log
copy && echo "Time `date +%F-%H:%M:%S` first copy...down" |tee -a /tmp/copy.log

#set m=6 and wait the row of cplist less than m , m can be set
#check again and copy again until m less than the value of set
declare -i m=11
while [ $m -gt 10 ] 
do
    echo  -e "\033[1;33m\n$(date +%F-%H:%M:%S) Check again begin ...\n##########################\033[0m" | tee -a /tmp/copy.log
    check && echo "Time `date +%F-%H:%M:%S` Check again...down" |tee -a /tmp/copy.log
    m=`cat cplist|wc -l`	
    echo  -e "\033[1;33m\n$(date +%F-%H:%M:%S) Copy again begin ...\n##########################\033[0m" | tee -a /tmp/copy.log
    copy echo "Time `date +%F-%H:%M:%S` Copy again...down" |tee -a /tmp/copy.log
done
echo "Less than 10 chunk chunkLevel=1 "
copy && echo "Time `date +%F-%H:%M:%S` The Last time Copy...down"|tee -a /tmp/copy.log

#stop src host and restart dest ds of host 
#dayumgr stop ds
#[ $? -eq 0 ] && ssh $host "/usr/local/dayu/bin/dayumgr restart ds" || echo "stop ds failed"
[ -f downlist ] && mv downlist cplist chunklist /tmp
echo "Finished. Check downlist,cplist,chunklist at /tmp" 
