#!/bin/bash
#caculate the time


begin=`date +%s`
echo $begin
sleep 60
stop=`date +%s`
echo $stop
echo $(( $stop - $begin ))



