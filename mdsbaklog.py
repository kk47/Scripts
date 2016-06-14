#!/usr/bin/env python
# mds checkpoint and mdslog backup

import sys
import os
import commands
import socket
import getopt
import time
import alertmgmt

import pdb
def mdslog_backup():
    ''' Backup log files, similar to chain mode backup'''
    
    global cmd
    baklogdir = bakdir + mdsvip + '/log/'

    if not os.path.isdir(baklogdir):
        try:
            os.makedirs(baklogdir)
        except OSError, msg:
            print msg
            return False

    for i in xrange(0, len(baknode), 1):
        if host == baknode[0]:
            pass
        elif host == baknode[i]:
            for j in xrange(i-1, -1, -1):
                cmd = 'rsync -aSqz --exclude=".*" -e "ssh  -o StrictHostKeyChecking=no" ' + baknode[j] + ':' + baklogdir + ' ' + baklogdir
                status, output = commands.getstatusoutput(cmd)
                if status != 0:
                    print output
                    print " Time %s: backup log from %s failed ,try next ..." % (time.ctime(), baknode[j])
                    continue
                else:
                    return True
        else:
            continue

        cmd = 'rsync -aSqz --exclude=".*" -e "ssh  -o StrictHostKeyChecking=no" ' + mdsvip + ':' + logpath + ' ' + baklogdir
        status, output = commands.getstatusoutput(cmd)
        if status != 0:
            print output
            return False
        else:
            return True

def para():
    ''' Load config file from nodes.cfg'''

    global baknode
    global bakdir
    global mdsvip

    try:
        f = open(cfgfile, "r")
        lines = f.readlines()
        f.close()
    except:
        print "nodes.cfg not exists."
        return False

    for line in lines:
        if line.strip().startswith('MDS_VIP='):
            vec = line.split('=')
            if len(vec) != 2:
                continue
            mdsvip = vec[1].strip()
            continue
        if line.strip().startswith('MDBAKS='):
            vec = line.split('=')
            if len(vec) != 2:
                continue
            baknode = vec[1].strip().split()
            continue
        if line.strip().startswith('MDBAK_DIR='):
            vec = line.split('=')
            if len(vec) != 2:
                continue
            bakdir = vec[1].strip() + '/'
            continue
    
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
    print u % (prog, prog)
    
    sys.exit(1)

def running_check():
    ''' Check whether the program is already running'''
    
    spid = str(os.getpid())
    if os.path.isfile(pidfile):
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

def baklog_check():
    ''' Check whether the content of log is right '''
    
    logdir = bakdir + '/' + mdsvip + '/log/'
    oldlogdir = bakdir + '/' + mdsvip + '/oldlog/' 

    # dump log check util success, if two failed logitem is the same, send alert mail
    checkcmd = dumplog + " -d " + logdir + " -c 2>/dev/null"
    status,output = commands.getstatusoutput(checkcmd)
    while (status != 0):
        if not output:
            print "Unknow dumplog error message"
            return False
        logitem = output.strip().split()[0]
        # retry log backup command
        st,out = commands.getstatusoutput(cmd)
        if st != 0:
            print out
            continue
        status,output = commands.getstatusoutput(checkcmd)
        newlogitem = output.strip().split()[0]
        if status != 0:
            if newlogitem == logitem:
                subject = "mds log backup failed in " + host 
                desc = "mds log backup failed"
                para = "ERROR ||| " + subject + " ||| Please check and recover ||| " + desc
                sa = alertmgmt.SendAlert()
                res, err = sa.sendMail(para)
                if not res:
                    print "Send alert mail failed"
                    print err
                return False
            else:
                continue
    
    # move log files to oldlogdir to make dumplog easier
    if not os.path.isdir(oldlogdir):
        os.mkdir(oldlogdir)
    flist = os.listdir(logdir)
    flist.sort()
    flist = flist[0:-2]
    for file in flist:
        src = logdir + file
        dst = oldlogdir + file
        os.rename(src, dst)

    return True

if __name__ == "__main__":
    
    pdb.set_trace()
    mdsvip = ''
    baknode = ''
    bakdir = "/var/local/dayu/mdbak/"
    logpath = "/dayudata/mds/log/"
    cfgfile = "/var/local/dayu/nodes.cfg"
    pidfile = "/var/run/dayubaklog.pid"
    ssh = "ssh -o StrictHostKeyChecking=no "

    dayu_install_dir = '/usr/local/dayu'
    if 'DAYU_INSTALL_DIR' in os.environ:
        dayu_install_dir = os.environ['DAYU_INSTALL_DIR']
    dumplog = dayu_install_dir + "/scripts/dumplog" 
    if not os.path.exists(dumplog):
        print "dumplog tool not exist"
        sys.exit(1)

    host = socket.gethostname()
    
    # Load config from nodes.cfg
    if not para():
        print "Time %s: get para failed" % time.ctime()
        sys.exit(1)
    
    # Getopts if logpath and mdsvip have been set 
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hp:v:")
    except getopt.GetoptError, msg:
        print msg
        sys.exit(1)

    for opt, arg in opts:
        if opt == '-p':
            logpath = arg
        elif opt == '-v':
            mdsvip = arg
        elif opt == '-h':
            usage()
        else:
            usage()

    if mdsvip == '' or baknode == '':
        print "Failed to get mds vip, exit"
        sys.exit(1)

    # Check whether localhost is backup node
    if host not in baknode:
        print "Time %s: %s not backup node" % (time.ctime(), host)
        sys.exit(1)

    # Check whether program is running
    # exit if running and write pid file if not running
    if not running_check():
        sys.exit(1)

    if not mdslog_backup():
        print "---Time %s : Backup mdslog.x files failed.---" % time.ctime()
    else:
        if not baklog_check():
            print "Time %s : Check log content failed." % time.ctime()
        else:
            print "---Time %s : Backup mdslog.x files succeed---" % time.ctime()
    
    if os.path.isfile(pidfile):
        os.unlink(pidfile)
    else:
        print "Missing pid file"
