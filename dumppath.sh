#!/bin/bash


#init 
cp ./oidfile ./oidfile.bak && echo > ./oidfile
cp ./badlist ./badlist.bak && echo > ./badlist

#get object id from chunkid
for chkid in `cat ./badlist`;do
    dayumdsmgmt -c GetChunkStatus -p "ChunkId=$chkid"|grep objectId|awk -F= '{print $2}' >> ./oidfile
done

#select path and oid from database;
for oid in `cat ./oidfile`; do
    mysql -u root -p123456 -e "select oid,path from dayu.metadata where oid=$oid;"|grep -v " | path " | grep -v "oid	path"
done
