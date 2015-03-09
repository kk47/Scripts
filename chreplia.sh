#!/bin/bash
#copy the chunk which replia is 1
# file chklist is the list of chunk with dir 
# file unlist is the list of checked file
# file cplist is the list of copy file




function check
{
find /dayudata/ds -type f|grep -v .uuid > chunklist
[ -f cplist ] && rm -f cplist
for chk in `cat chunklist`
do
    [ -f unlist ] && grep $chk unlist
    if [ $? -eq 0 ]
    then
        echo "$chk checked" 
    else
        id=`cat chunklist |awk -F"/" '{print $6}'` 
        dayumdsmgmt -c GetChunkStatus -p chunkId=$id|grep "chunkLevel=1"
        if [ $? -eq 0 ] 
        then
            echo $chk >> cplist
            echo $chk >> unlist
        else
            echo $chk >> unlist
        fi
    fi
done
}

function copy
{
declare -i i=0
n=${#uuid[@]}
for file in `cat cplist`
do
    did=`echo $file|awk -F"/" '{print $5}'`
    scp $file $host:/dayudata/ds/${uuid[$i]}/$did/ &>/dev/null
    [ $? -eq 0 ] && echo "$file copy ok" 
    (( $i < $n )) && let i++ || i=0
done
}


host=d01
uuid=(`ssh $host "ls /dayudata/ds"`)
check
copy
check && m=`cat cplist|wc -l`
while [ m -gt 5 ] 
do
    copy
    check && m=`cat cplist|wc -l`
done
dayumgr stop ds
[ $? -eq 0 ] && ssh $host "dayumgr restart ds"
       
    
         





