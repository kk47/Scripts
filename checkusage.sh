#!/bin/bash
# check dir usage from database

if [ $# != 1 ]; then
	echo "Usage: bash `basename $0` path"
	exit 1
fi
path=$1

echo "Path: $path"
echo -e "Date \tNewFiles NewCapacity"
for (( i=9; i >= 2; i-- )); do
	#echo "$timestamp2" 
	timestamp1="2014-12-$i"
	j=`echo "$i - 1" | bc`
	timestamp2="2014-12-$j"
        echo -e -n "$timestamp1\t"
	mysql -u root -p123456 -e "select count(*),sum(size) from dayu.metadata where path like '$path/%' and type='FILE' and mtime > \"${timestamp2}\" and mtime < \"${timestamp1}\" ;" | grep -v "count"
done

echo ""
