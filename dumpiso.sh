#!/bin/bash
# check and dump iso file 
# There is three file you have to know,$isolist made by find,and it will be reduce by $oldlist;
# $oldlist is the file which already dumped;$breaklist is the file which breaked;and $Logdir/dumpiso.log is the log file.
# Check the dumpiso.log if you want to know what the script have done.

#set -x

function Usage()
{
    echo "This tool is used to check & extract ISO files from given directory."
    echo "Usage: `basename $0` -s /mnt/dayu/hntv -d /mnt/dayu/isodump -m /mnt/dayu/iso -c '0 */2 * * *' "
    echo "       `basename $0` -s /mnt/dayu/hntv -d /mnt/dayu/isodump -m /mnt/dayu/iso"
    echo "       `basename $0` -s /mnt/dayu/hntv -d /mnt/dayu/isodump -m /mnt/dayu/iso -R" 
    echo "Options:"
    echo "  -s  directory  Source directory which contains iso files. if -c "
    echo "                 option used, a absolute path should be used."
    echo "  -d  directory  Target directory to dump iso files. if -c option "
    echo "                 used, a absolute path should be used."
    echo "  -c  crontab    Set a cron job to run this tool periodically"
    echo "                 the \"crontab\" has same syntax as /etc/crontab, if -c "
    echo "                 option not present, this command run immediately "
    echo "                 and only run once"
    echo "  -m  directory  Iso backup directory after being extracted. should be "
    echo "                 absolute path when -c option used"
    echo "  -R  remove     remove the iso file from directory isobak."
    echo "  -h  Usage" 
    echo "Notes:"
    echo "  Please check /var/log/dumpiso/dumpiso.log for log infomation."
    exit 0
}

#find the iso change before 3 hours 
function Mkisolist() 
{
    [ -f $isolist ] && cat /dev/null > $isolist
    find ${sourcedir} -name "*.[iI][sS][oO]" -mmin +180  >> \
    $isolist && echo "$isolist has been created." &>> $logfile

    for file in `cat $isolist`
    do
        [ -f $oldlist ] || cat /dev/null > $oldlist
        [ -f $breaklist ] || cat /dev/null > $breaklist
        local var=$(echo $file|sed 's/\//\\\//g')
        cat $oldlist |grep $file &>/dev/null && sed -i "/$var/d" \
        $isolist && echo "Reducing $file from $isolist" &>> $logfile
        cat $breaklist |grep $file &>/dev/null && sed -i "/$var/d" \
        $isolist && echo "Reducing $file from $isolist" &>> $logfile
    done
}

#use isosize to judge 
function Jisosize()
{
    for file1 in `cat $isolist`
    do
        lsize=`ls -l "$file1" |awk '{print $5}'`
        isize=`isosize "$file1"`
        local var=$(echo "$file1"|sed 's/\//\\\//g')
        if [[ $lsize -ne $isize ]]
        then
            sed -i "/$var/d" $isolist
            echo "$file1" >> $breaklist 
            echo "Warning:$file1 have the wrong iso size." &>> $logfile
        fi
    done
}

#use dayustat -v to judge
function Jdayustat()
{
    DAYU_MNT_PNT=`echo "$DAYU_MNT_PNT" |sed 's/\/$//'`
    df -h | grep "$DAYU_MNT_PNT" &> /dev/null 
    if [[ $? -ne 0 ]]
    then
        echo "dayufs not mounted" &>> $lgogfile
        exit 1
    fi

    for file2 in `cat $isolist`
    do
        local dayudir=`echo "$file2" | awk -F"$DAYU_MNT_PNT" '{print $2}'`
        local var=$(echo "$file2" | sed 's/\//\\\//g')
        dayustat -v "$dayudir" | grep "Corrupted" &>/dev/null
        if [[ $? -eq 0 ]] 
        then
            sed -i "/$var/d" $isolist 
            echo "$file2" >> $breaklist
            echo "Warning:$file2 is Corrupted." &>> $logfile
        fi
    done
}

#mount -o loop file /tmp/file judge  
function Jmount()
{
    mkdir -p $tmp_mount_dir/tmpmnt  &>> $logfile
    for file3 in `cat $isolist`
    do
    #    local dayudir=`echo $file3|awk -F"$mountdir" '{print $2}'`
        df -h | grep "$tmp_mount_dir/tmpmnt" &> /dev/null
        if [[ $? -eq 0 ]]
        then
            umount "$tmp_mount_dir/tmpmnt" &> /dev/null
            if [[ $? -ne 0 ]]
            then 
                echo "Failed to umount temp mount point."
                exit 1;
            fi
        fi

        local var=$(echo $file3|sed 's/\//\\\//g')
        echo "mount -o loop \"$file3\"  $tmp_mount_dir/tmpmnt" #&>/dev/null 
        mount -o loop "$file3"  $tmp_mount_dir/tmpmnt #&>/dev/null 
        if [[ $? -ne 0 ]]
        then
            sed -i "/$var/d" $isolist
            echo "$file3" >> $breaklist
            echo "Warning:$file3 mount failed." &>> $logfile
        fi
        umount $tmp_mount_dir/tmpmnt &>/dev/null
    done
}

#dump file to targetdir
function Dumpfile()
{
    for file4 in `cat $isolist`
    do
        local isopath=`echo "$file4" |awk -F"$sourcedir" '{print $2}'`
        local target_isopath=`echo "$file4" |awk -F"$sourcedir" '{print $2}'|sed 's/\.iso//g'`
        local uid=`ls -l "$file4" |awk '{print $3}'`
        local gid=`ls -l "$file4" |awk '{print $4}'`
        mount -o loop "$file4"  $tmp_mount_dir/tmpmnt #&>/dev/null 
        if [[ $? -eq 0 ]]
        then
            echo "Copy $file4 starting ... ..." &>> $logfile
            local datetime=`date +%s`
            if [[ -d "$targetdir/$target_isopath" ]] 
            then
                echo "$targetdir/$target_isopath/ exist, rename it as a backup." &>> $logfile
                mv  "$targetdir/$target_isopath" "$targetdir/$target_isopath.bak.$datetime"           
            fi
            mkdir -p "$targetdir/$target_isopath"

            \cp -rfa $tmp_mount_dir/tmpmnt/* "$targetdir/$target_isopath" &>> $logfile
            if [[ $? -eq 0 ]]
            then
                chown -R $uid:$gid "$targetdir/$target_isopath"
                echo "Copy $file4 iso done." &>> $logfile

                grep "$file4" $oldlist &>/dev/null || echo "$file4" >> $oldlist
                local var=$(echo "$file4"|sed 's/\//\\\//g')
                sed -i "/$var/d" $isolist

                if [[ -d "$bakdir/$target_isopath" ]] 
                then
                    echo "$bakdir/$target_isopath exist, rename it as a backup." &>> $logfile
                    mv  "$bakdir/$target_isopath" "$bakdir/$target_isopath.old.$datetime"           
                fi
                local isodir=$(dirname "$bakdir/$isopath")
                local fisodir=$(echo "$file4" |awk -F"$sourcedir" '{print $2}'|awk -F"/" '{print $2}')
                mkdir -p "$isodir"
                mv "$file4" "$isodir" &>> $logfile 

                #local updir=$(dirname "$file4") # ONLY two level supported
                local cnt=$(find "$sourcedir/${fisodir}" -name "*.[iI][sS][oO]" | wc -l)
                if [[ "$cnt" -eq "0" ]] 
                then 
                    if [[ ! `echo $fisodir|grep ".iso"` ]] 
                    then
                        cat /dev/null > $tmp_mount_dir/otherfile
                        find "$sourcedir/$fisodir" -type f >> $tmp_mount_dir/otherfile
                        for obj in `cat $tmp_mount_dir/otherfile`
                        do
                            fpath=`echo "$obj" |awk -F"$sourcedir" '{print $2}'`
                            bakpath=$(dirname $fpath)
                            mv $obj $bakdir/$bakpath/
                        done 
                        rm -fr "$sourcedir/$fisodir" &>> $logfile
                    fi
                fi
            else 
                echo "Warning:$file4 copy is corrupt." &>> $logfile
            fi
            
            umount $tmp_mount_dir/tmpmnt
        else 
            echo "Failed to mount $file4." &>> $logfile
        fi
    done
}

function Addcron()
{
    [ -f /usr/bin/$base ] || cp $base /usr/bin/
    chmod +x /usr/bin/$base
    if [[ -f /etc/cron.d/dumpiso ]]
    then
        echo "$cron root /usr/bin/$base -s $sourcedir -d $targetdir -m $bakdir &" >> /etc/cron.d/dumpiso
    else
        echo "$cron root /usr/bin/$base -s $sourcedir -d $targetdir -m $bakdir &" > /etc/cron.d/dumpiso
    fi

}

function Remove()
{
    for file5 in `cat $isolist`
    do
        local isopath=`echo "$file5" |awk -F"$sourcedir" '{print $2}'` 
        rm -f "$bakdir/$isopath" && \
        echo "Remove $isoname from isobak." &>> $logfile    
    done
}

#main
# Parse parameter
while getopts 's:d:m:c:hR' OPT; do
    case $OPT in
        s)
            sourcedir=$OPTARG
            ;;
        d)
            targetdir=$OPTARG
            ;;
        m)
            bakdir=$OPTARG
            ;;
        c)
            cron=$OPTARG
            ;;
        R)
            Remove=1
            ;;
        h)  Usage
            ;;
        ?)  Usage    
    esac
done

sourcedir=`echo "$sourcedir" |sed 's/\/$//'`
targetdir=`echo "$targetdir" |sed 's/\/$//'`
bakdir=`echo "$bakdir" | sed 's/\/$//'`
tmp_mount_dir=/tmp/dayu_mtmp
Logdir=/var/log/dumpiso
[ x"$sourcedir" = x -o x"$targetdir" = x -o x"$bakdir" = x ] && Usage
[ -d $tmp_mount_dir ] || mkdir -p $tmp_mount_dir 
[ -d $Logdir ] || mkdir -p $Logdir
mkdir -p "$targetdir"
mkdir -p "$bakdir"
logfile="$Logdir/dumpiso.log"
oldlist="$Logdir/oldlist"
breaklist="$Logdir/breaklist"
isolist="$tmp_mount_dir/isolist"

base=$(basename "$0")
if [[ -f /var/run/$base.pid ]]
then
    Pid=`cat /var/run/$base.pid`
    ps aux | grep -v grep | grep "$Pid" | grep "$base" &>/dev/null
    if [[ $? -eq 0 ]]
    then
        echo "$base already runing!" &>> $logfile
        exit 1
    else
        echo "$$" > /var/run/$base.pid
    fi
else
    echo "$$" > /var/run/$base.pid
fi

if [[ x"$cron" != x ]]  
then
    Addcron
    cat > /etc/logrotate.d/dumpiso <<   EOF
$logfile {
    daily
    missingok
    rotate 7
    compress
    copytruncate
    notifempty
    create 644 root root
    #su root root 
}
$oldlist {
    daily
    missingok
    rotate 7
    compress
    copytruncate
    notifempty
    create 644 root root
    #su root root 
}
EOF
    rm -f /var/run/$base.pid
    exit 0
fi

echo -e "\033[1;33m\\n$(date +%F-%T) Runing ...-------------------------\033[0m" &>> $logfile
Mkisolist && echo "$isolist is refresh" &>> $logfile 

if [[ `which isosize` ]]
then
    Jisosize
    echo "isosize check done." &>> $logfile
fi

if [[ `which dayustat` ]] 
then
    Jdayustat
    echo "dayustat check done." &>> $logfile
fi

Jmount && echo "mount check done." &>> $logfile
Dumpfile && echo "dump isofile done." &>> $logfile

if [[ "$Remove" -eq 1 ]]
then
    Remove
fi

rm -f /var/run/$base.pid
