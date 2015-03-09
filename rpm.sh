#!/bin/bash

awk -F" " '/Install/{print $2}' /root/install.log |sed 's/^[0-9]*://g' >> /root/rpmlist
SRC_RPMS=/root/cdrom/Packages      
DST_RPMS=/sdb/iso/Packages
packages_list=/root/rpmlist
number_of_packages=`cat $packages_list | wc -l`  
i=1  
while [ $i -le $number_of_packages ] ;  
do  
    name=`head -n $i $packages_list | tail -n -1`  
    echo "cp $SRC_RPMS/$name* $DST_RPMS/"   
    cp $SRC_RPMS/$name* $DST_RPMS/          
    i=`expr $i + 1`  
done 

