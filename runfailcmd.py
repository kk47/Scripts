#!/usr/bin/evn python
# run failed cmd according to .dayu/failedcmd/ record
import os
import sys
import commands
import socket,fcntl,struct

def getIpAddr(ifname):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    return socket.inet_ntoa(fcntl.ioctl(
                s.fileno(),
                0x8915, # SIOCGIFADDR 
                struct.pack('256s', ifname[:15])
                )[20:24])

if __name__ == "__main__": 
    ifname = ["bond0","em1","eth0"]
    for inte in ifname:
        try:
            ip = getIpAddr(inte)    
        except IOError,msg:
            continue

    hostname = socket.gethostname()
    #print hostname
    dir1 = "/mnt/dayu/.dayu/failedcmd/" + hostname + "/"
    dir2 = "/mnt/dayu/.dayu/failedcmd/" + ip + "/"
    #print dir1,dir2
    if os.path.isdir(dir1):
        dir = dir1
    elif os.path.isdir(dir2):
        dir = dir2
    else:
        sys.exit(1)
    lcmd = 'ls ' + dir + '|grep -v .error'
    output = commands.getoutput(lcmd)
    output = output.split()
    #print output
    print len(output)
    while len(output) > 0:
        print len(output)
        name = min(output)
        file = dir + name
        output.remove(name)
    
        try:
            f = open(file,'r')
            cmd = f.read()
            f.close
            if cmd.split() == []:
                dcmd = 'rm -f ' + file
                os.system(dcmd)    
                continue

            f = open(file,'w')
            status,info = commands.getstatusoutput(cmd)
            if status != 0:
                f.write(cmd)
                f.close()
                ename = file + ".error"
                ef = open(ename,'w')
                ef.write(info)
                ef.close()
            else:
                os.remove(file)
        except:
            raise
