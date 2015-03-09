#!/bin/bash
#copy the chunk from old disk to the new disk
# file chklist is the list of chunk 
# file badlist is the corrupted chunk

function copy
{
    if [[ ! -f ./chklist ]]; then
        echo "There is no chklist file"
        exit 1 
    fi

    for chk in `cat chklist`
    do
        fdir=`echo "$chk" |rev|cut -c -6|rev|cut -c -3`
        if [ -f $olddir/$fdir/$chk ]; then
            cp $olddir/$fdir/$chk /$newdir/$fdir/ >> ./copy.log
            if [ $? -ne 0 ]; then
                echo "$chk copy failed"
                rm -f /$newdir/$fdir/$chk
                echo "$chk" >> ./badlist
            else
                echo "$chk copy ok"
            fi
        else
            echo "$chk not exist"
            echo "$chk" >> ./nonexistlist
        fi
    done
}

#judge the input parm
if [ $# -ne 2 ];
then
    echo "Usage  $0 olddiskdir newdiskdir " 
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

#get old and new disk dir
olddir=$1
newdir=$2

# init files
echo > ./badlist
echo > ./nonexistlist

# init new disk dir
for i in `seq -f %03g 0 999`; do 
    mkdir -p $2/$i
done
logname="./$(date +%F-%H%M%S)_copy.log"
copy | tee -a $logname

echo "Finished. Check badlist nonexistlist copy.log." 
