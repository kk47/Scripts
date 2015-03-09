#!/bin/bash
# check dir usage from database

function usage
{
    cat << EOF
Usage:
    -p path, the dir which you want check in dayu
    -t year-month, like 2015-02
    -h help
Examples:
    `basename $0` -p /dayu/path/ -t 2015-02
EOF
}


function check_usage
{
    echo -e "Date \tNewFiles NewCapacity(T)"
    echo -e -n "$mtime(total)\t"
    mysql -u root -p123456 -e "select count(*),sum(size/1099511627776) from dayu.metadata where path like '$path/%' and type='FILE' and mtime like '$mtime%';" | grep -v "count"
    echo -e -n "$mtime-31\t"
    mysql -u root -p123456 -e "select count(*),sum(size/1099511627776) from dayu.metadata where path like '$path/%' and type='FILE' and mtime like '$mtime-31%';" | grep -v "count"
    for i in $(seq -f "%02g" 31 -1 2); do
        #echo "$timestamp2" 
        timestamp1="$mtime-$i"
        j=`echo "$i - 1" | bc`
        timestamp2="$mtime-$j"
        echo -e -n "$timestamp2\t"
        mysql -u root -p123456 -e "select count(*),sum(size/1099511627776) from dayu.metadata where path like '$path/%' and type='FILE' and mtime > \"${timestamp2}\" and mtime < \"${timestamp1}\" ;" | grep -v "count"
    done
    echo ""
}

while getopts 'p:t:h' options; do
    case $options in
        p)
            path=$OPTARG
            ;;
        t)
            mtime=$OPTARG
            ;;
        h)
            usage
            exit 0
            ;;
        ?)
            usage
            exit 1
            ;;
    esac
done

if [[ -z "$path" ]]; then
    echo "Path is set to /"
fi

if [[ -z "$mtime" ]]; then
    mtime=$(date --date="-1 month" +%Y-%m)
    echo "Mtime is set to $mtime"
fi

check_usage
