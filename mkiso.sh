#!/bin/bash
#make iso file,sourcedir is the directory of you place iso file
#mountdir is the place where origin iso mount 
function usage()
{
    echo "Usage:bash `basename $0` /sdb/CentOS6.4_X86_64_AutoV3.iso /root/iso-6.4 /root/cdrom/"
    echo "Explain:"
    echo "      /sdb/CentOS6.4_X86_64_AutoV2.iso is target dir and filename"
    echo "      /root/isobuild is the directory of you place iso file"
    echo "      /mnt is the place where origin iso mount"
    exit 1
}
function rebuild_repo() 
{
cd $sourcedir
rm -f $sourcedir/repodata/*
cp $mountdir/repodata/27* $sourcedir/repodata/ 
createrepo -g $sourcedir/repodata/27* $sourcedir/
declare -x discinfo=`head -1 .discinfo`
createrepo -u "media://$discinfo" -g $sourcedir/repodata/2727fcb43fbe4c1a3588992af8c19e4d97167aee2f6088959221fc285cab6f72-2727fcb43fbe4c1a3588992af8c19e4d97167aee2f6088959221fc285cab6f72-c6-x86_64-comps.xml $sourcedir/
rm -f $sourcedir/repodata/27* 
for i in `ls $sourcedir/repodata/*.gz`
do
    echo $i
    n=`ls $i |wc -L`
    [[ $n -gt 140 && $n -lt 200 ]] && rm -f $i
done
echo "Done"
}

[ $# -ne 3 ] && usage 
sourcedir=`echo $2|sed 's/\/$//'`
mountdir=$3
read -n1 -p "Are you want to rebuild repo metadata(Y/N):" input
if [[ $input == y || $input == Y ]];then
    echo -e "\nStart rebuild repo file..."
    rebuild_repo
fi
sleep 3
echo "Start create iso file..."
mkisofs -o $1 -J -r -v -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -V " CentOs_X86_64_AutoInstall_DVD" $sourcedir 
echo "Done."
implantisomd5 --force $1
