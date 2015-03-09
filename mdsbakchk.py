#!/usr/bin/env python
# Backup mds checkpoint, get checkpoint from mdsvip.
# This backup job will truly run at set time like Sat:08, mean 8 a.m at Saturday
# Two or more backup node will run in different time, if first one is 8 a.m then second is 9 a.m
# Sleep 5 minute and try 3 times at most if rsync job is failed.

import sys
import os
import commands
import time
import socket
import shutil
import getopt
import alertmgmt

def checkpiont_backup():

    tmpchkdir = bakdir + mdsvip + '/chktmp/'
    oldchkdir = bakdir + mdsvip + '/checkpoint'
    bakchkdir = oldchkdir + '.bak'
    
    # create backup command 
    try:
        if not os.path.isdir(tmpchkdir):
            try:
                os.makedirs(tmpchkdir)
            except OSError, msg:
                print msg 
                return False
        else:
            print 'Time %s: %s exists,mabye something wrong.' % (time.ctime(), tmpchkdir)
            baktmp = bakdir + mdsvip + '/chktmp' + str(time.time())
            os.renames(tmpchkdir,baktmp)
    except OSError, msg:
        print msg
        return False

    cmd = 'rsync -aSqz --exclude ".bak*" --exclude "*-tmp*"  -e "ssh  -o StrictHostKeyChecking=no" ' + mdsvip + ':' + chkpath + '/*' + ' ' + tmpchkdir

    # execute commands , try 5 times if rsync failed
    count = 1
    status,output = commands.getstatusoutput(cmd)
    while ( status != 0 ):
        shutil.rmtree(tmpchkdir)
        if ( count > 5 ):
            print "Time %s: backup checkpoint failed, keep old backup file." % time.ctime()
            return False
        try:
            os.makedirs(tmpchkdir)
        except OSError, msg:
            print msg
            return False

        status,output = commands.getstatusoutput(cmd)
        count += 1
    
    if not bakchk_check():
        print "Time %s : Check checkpoint content failed." % time.ctime()
        baktmp = bakdir + mdsvip + '/chktmp' + str(time.time())
        os.renames(tmpchkdir,baktmp)
        return False

    # Rename directories
    try:
        if not os.path.exists(bakchkdir):
            print 'Time %s: checkpoint.bak not exists' % time.ctime()
            if not os.path.exists(oldchkdir):
                print 'Time %s: oldchkdir not exists' % time.ctime()
                os.renames(tmpchkdir,oldchkdir)
            else:
                os.renames(oldchkdir,bakchkdir)
                os.renames(tmpchkdir,oldchkdir)  
        else:
            print 'Time %s: checkpoint.bak exists , replace it ...'  % time.ctime()
            if os.path.exists(oldchkdir):
                shutil.rmtree(bakchkdir)
                os.renames(oldchkdir,bakchkdir)
                os.renames(tmpchkdir,oldchkdir)
            else:
                os.renames(tmpchkdir,oldchkdir)
    except OSError, msg:
        print msg
        return False

    return True

def clean_log():
    ''' delete the old mdslog.x files '''

    oldlogdir = bakdir + mdsvip + '/oldlog/'
    
    if not os.path.exists(oldlogdir):
        msg = "old log dir not exist"
        return False, msg
    cmd = 'find %s -type f -mtime +8 ' % oldlogdir  + ' -exec /bin/rm -f {} \;'
    status,output = commands.getstatusoutput(cmd)
    if status != 0:
        return False, output
    else:
        return True, ''
    
def bakchk_check():
    ''' Check whether the content of checkpoint is right '''
   
    checkdir =  bakdir + '/' + mdsvip + '/chktmp/' 
    cmd = dumpchkpnt + " -d " + checkdir + " -c " 
    status,output = commands.getstatusoutput(cmd)
    if status == 0:
        return True
    else:
        print output
        subject = "mds checkpoint backup failed in " + host 
        desc = "mds checkpoint backup failed, Error message: " + output
        para = "ERROR ||| " + subject + " ||| Please check and recover ||| " + desc
        sa = alertmgmt.SendAlert()
        res, err = sa.sendMail(para)
        if not res:
            print "Send alert mail failed"
            print err
        return False

def running_check():
    ''' Check whether the program is already running'''
     
    spid = str(os.getpid())
    if os.path.exists(pidfile):
        try:
            with open(pidfile,'r') as f:
                pid = f.read().strip()
                if pid:
                    pid = int(pid)
                    os.kill(pid, 0)
                    print "process %s is running" % pid
                return
        except OSError:
            print "program not running but pidfile exist, rewrite new pid"
            os.remove(pidfile)
            open(pidfile, 'w').write(spid)
            return True
    else:
        open(pidfile, 'w').write(spid)
        return True

def para():
    
    global baknode 
    global chkcron
    global bakdir
    global mdsvip

    try:
        f = open(cfgfile,"r")
        lines = f.readlines()
        f.close()
    except:
        print "nodes.cfg not exists."
        return False

    for line in lines:
        if line.strip().startswith('MDS_VIP='):
            vec = line.split('=')
            if len(vec) != 2 :
                continue
            mdsvip = vec[1].strip()
            continue
        if line.strip().startswith('MDBAKS='):
            vec = line.split('=')
            if len(vec) != 2 :
                continue
            baknode = vec[1].strip().split(' ')
            continue
        if line.strip().startswith('MDBAK_DIR='):
            vec = line.split('=')
            if len(vec) != 2 :
                continue
            bakdir = vec[1].strip() + '/'
            continue
        if line.strip().startswith('CHECKPOINT_CRON='):
            vec = line.split('=')
            if len(vec) !=2 :
                continue
            chkcron = vec[1].strip()
        
    if baknode == '':
        return
    else:
        return True

def usage():
    u = """
    Name:
        %s - back up checkpoint and mdslog 
    
    Synopsis:
        %s [-h] [-p path] [-v mdsvip]
    
    Description:
        Arguments are as following:
            -h      print the help message
    """
    prog = os.path.basename(sys.argv[0])
    print "Usage :"
    print u %(prog, prog)
    
    os.unlink(pidfile)
    sys.exit(1)

if __name__ == "__main__":

    mdsvip = ''
    baknode = ''
    chkcron = 'Sat:06'
    bakdir = "/var/local/dayu/mdbak/"
    pidfile = "/var/run/dayubakchk.pid"
    cfgfile = "/var/local/dayu/nodes.cfg"
    chkpath = "/dayudata/mds/checkpoint"
    ssh = "ssh -o StrictHostKeyChecking=no "
    
    dayu_instatll_dir = '/usr/local/dayu'
    if 'DAYU_INSTALL_DIR' in os.environ:
        dayu_instatll_dir = os.environ['DAYU_INSTALL_DIR']
    dumpchkpnt = dayu_instatll_dir + "/scripts/dumpchkpnt" 
    if not os.path.exists(dumpchkpnt):
        print "dumpchkpnt tool not exist"
        sys.exit(1)

    host = socket.gethostname() 
    
    # Check whether program is running
    # exist if running and write pid file if not running
    if not running_check():
        sys.exit(1)

    try:
        opts, args = getopt.getopt(sys.argv[1:], "hp:v:")
    except getopt.GetoptError, msg:
        print msg

    for opt, arg in opts:
        if opt == '-p':
            chkpath = arg
        elif opt == '-v':
            mdsvip = arg
        elif opt == '-h':
            usage()
        else:
            usage()

    # get baknode and mdsvip
    if not para():
        print "get para failed."
        os.unlink(pidfile)
        sys.exit(1)
    
    # main
    tf = []
    for i in xrange(len(baknode)):
        base = int(chkcron.split(':')[1])
        tf.append(base + 1*i)
        if host == baknode[i]:
            if tf[i] >= 24:
                tf[i] = tf[i] - 24

            if tf[i] <= 9:
                tmp = '0' + str(tf[i])
            else:
                tmp = str(tf[i])

            chkcron = chkcron.split(':')[0] + ':' + tmp + ':00' 
        else:
            continue
    now = time.localtime()
    if time.strftime('%a:%H:%M',now) == chkcron:
    #if time.localtime() == now:
        ret = checkpiont_backup()
        if ret == False:
            print 'Time %s:checkpoint backup failed.' % time.ctime()
        else:
            res, msg = clean_log()
            if not res:
                print msg
                print "Time %s : Clean old log failed." % time.ctime()
            else:
                print 'Time %s:Backup checkpoint succeed.' % time.ctime()
    else:
        print "Next running time : %s " % chkcron 

    # Remove pid file
    if os.path.isfile(pidfile):
        os.unlink(pidfile)
    else:
        print "Missing pid file"
