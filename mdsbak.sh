#!/bin/bash
# backup checkpoint and mdslog
# checkpoint:20min incremental backup,every 30 incremental backup have a full checkpiont.
# mdslog:every 30 record will flush to disk.


datadir="/dayudata"

duser="root"
ssh_option=" -o StrictHostKeyChecking=no"

nodedir="/var/local/dayu"
nodefile="${nodedir}/nodes.cfg"
mbdir="${nodedir}/mdbak"

remove=false

baknode=""
mdsnode=""
declare -a dmbs
declare -a mdsvips
declare -a olddmbs
declare -a mdse

function fullchkp_backup 
{
            





