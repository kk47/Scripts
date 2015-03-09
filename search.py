#! /usr/bin/env python

import usermgmt_pb2
import usermgmt
import os
import pwd
import grp
import fcntl
import re
import xattr
import sys
import getopt

__metaclass__ = type

class collect(usermgmt.dayuusermgmt):
    def __init__(self):
        usermgmt.dayuusermgmt.__init__(self)

    def initialization(self):
        if os.path.exists(self.dir):
            self.Init = True
            return False, 'Has been initialized.'

        try:
            os.mkdir(self.dir)
            os.mknod(self.ulist_fn)
            os.mknod(self.glist_fn)
            os.mknod(self.sys_u_fn)
            os.mknod(self.sys_g_fn)
            os.mknod(self.cifs_fn)
            os.mknod(self.nfs_fn)
            os.mknod(self.ftp_fn)
            if not os.path.isfile('/var/log/dayu/umgmt.log'):
                os.mknod('/var/log/dayu/umgmt.log', 0644)
                f = open('/etc/logrotate.d/umgmt', 'w+')
                f.write('/var/log/dayu/umgmt.log\n{\n\tdaily\n\tsize=20M\n\tmissingok\n\trotate 5\n\tcompress\n\tcopytruncate\n\tnotifempty\n\tcreate 644 root root\n\tsharedscripts\n\tprerotate\n\t/usr/bin/chattr -a /var/log/dayu/umgmt.log\n\tendscript\n\tsharedscripts\n\tpostrotate\n\t/usr/bin/kill -HUP syslog\n\t/usr/bin/chattr +a /var/log/dayu/umgmt.log\n\tendscript\n}')
                f.close()
        except Exception, e:
            raise
            return False, 'Failed initialization, %s' % e
        
        self.Init = True
        return True, 'Initialization.'

    def Store_The_Original_User(self):
        if not self.Init:
            return False, 'Failed to initialization'

        sys_gl = usermgmt_pb2.GroupList()
        for i in grp.getgrall():
            if i[2] < 500 or i[2] == 65534:
                sg = sys_gl.groups.add()
                sg.group = i[0]
                sg.gid = i[2]

        dayu_gl = usermgmt_pb2.GroupList()
        for i in grp.getgrall():
            if i[2] >= 500:
                g = dayu_gl.groups.add()
                g.group = i[0]
                g.gid = i[2]

        with open(self.sys_u_fn, 'r+') as fn:
            sys_ul = usermgmt_pb2.UserList()
            for i in pwd.getpwall():
                if i[2] < 500 or i[2] == 65534:
                    su = sys_ul.users.add()
                    su.user = i[0]
                    su.uid = i[2]
                    su.workdir = i[5]
                    for j in sys_gl.groups:
                        if i[3] == j.gid:
                            su.group = j.group
                            su.gid = i[3]
                    str1 = sys_ul.SerializeToString()
            fn.write(str1)
            fn.close()
        
        if os.path.isfile('./UserPwd'):
            passwd = ''
            with open('./UserPwd') as f:
                for i in f.readlines():
                    passwd += i
                f.close()
            passwd = passwd.rstrip('\n').split('\n')

        with open(self.ulist_fn, 'r+') as fn:
            dayu_ul = usermgmt_pb2.UserList()
            str2 = ''
            for i in pwd.getpwall():
                if i[2] >= 500 and i[2] != 65534:
                    u = dayu_ul.users.add()
                    u.user = i[0]
                    u.uid = i[2]
                    if i[5].find(self.dayu_mp) == 0:
                        u.workdir = i[5].split(self.dayu_mp)[1]
                    #else:
                    #    u.workdir = i[5]

                    if 'passwd' in locals().keys():
                        for k in passwd:
                            info = k.split(':')
                            if info[0] == u.user:
                                u.passwd = info[1]
                                break

                    for j in dayu_gl.groups:
                        if i[3] == j.gid:
                            u.group = j.group
                            u.gid = i[3]
                        elif i[3] == 50:
                            u.gid = 50
                            u.group = 'ftp'

                    str2 = dayu_ul.SerializeToString()
            fn.write(str2)
            fn.close()

        with open(self.sys_g_fn, 'r+') as fn:
            for i in sys_gl.groups:
                for j in sys_ul.users:
                    if i.gid == j.gid:
                        i.userlist.append(j.user)
                str3 = sys_gl.SerializeToString()
            fn.write(str3)
            fn.close()

        with open(self.glist_fn, 'r+') as fn:
            for i in dayu_gl.groups:
                for j in dayu_ul.users:
                    if i.gid == j.gid:
                        i.userlist.append(j.user)
                str4 = dayu_gl.SerializeToString()
            fn.write(str4)
            fn.close()

        xattr.xattr(self.dir).set('IdSeq', '5999')
        return True, 'Done'

    def Search_CIFS_Original_Records(self):
        if not self.Init:
            return False, 'Failed to initialization'

        if not os.path.exists('./CIFS_list'):
            return True, ''

        with open ('./CIFS_list') as f:
            fcntl.flock(f, fcntl.LOCK_EX)            
            cifs = ''
            for i in f.readlines():
                cifs += i
            fcntl.flock(f, fcntl.LOCK_UN)
            f.close()

        cifs = cifs.split('host = ')

        if len(cifs) == 0: return True, ''

        with open(self.cifs_fn, 'r+') as f:
            cifs_pro = usermgmt_pb2.CIFSList()
            for i in cifs:
                if len(i) == 0: continue
                i = i.split('\n')
                dayu_cifs = cifs_pro.confs.add()
                for j in i:
                    if j.startswith('['):
                        dayu_cifs.name = j.lstrip('[').rstrip(']')
                    
                    elif j.startswith('comment'):
                        dayu_cifs.remark = j.split('=')[1].lstrip(' ')
                    
                    elif j.startswith('path'):
                        Dir = j.split('=')[1].lstrip(' ')
                        if Dir.find(self.dayu_mp) == 0:
                            dayu_cifs.dir = j.split(self.dayu_mp)[1]
                        else:
                            dayu_cifs.dir = Dir

                    elif j.startswith('browseable'):
                        if j.split('=')[1].lstrip(' ') == 'yes':
                            dayu_cifs.browseable = True
                        else:
                            dayu_cifs.browseable = False

                    elif j.startswith('writeable'):
                        if j.split('=')[1].lstrip(' ') == 'yes':
                            dayu_cifs.writable = True
                        else:
                            dayu_cifs.writable = False
                
                    elif j.startswith('valid users'):
                        users = j.split('=')[1].lstrip(' ').split(' ')
                        for k in users:
                            dayu_cifs.users.append(k)

                    elif j == '':
                        continue

                    else:
                        if j == 'all':
                            res, hosts = usermgmt.dayuusermgmt.loadHost(self)
                            if not res:
                                return res, hosts
                        else:
                            hosts = j.split(' ')

                        for k in hosts:
                            dayu_cifs.servers.append(k)

                str1 = cifs_pro.SerializeToString()
            f.write(str1)
            f.close()

        return True, 'Done'

    def Search_Ftp_Original_Records(self):
        if not os.path.isfile('./FTP_list'):
            return True, ''

        try:
            with open('./FTP_list') as f:
                lines = f.readlines()
                f.close()
        except:
            raise
            
        if len(lines) == 0:
            return True, ''

        ftp = usermgmt_pb2.FTPList()
        with open(self.ftp_fn, 'r+') as f:
            for i in lines:
                user = i.split(':')[0]
                servers = i.split(':')[1].rstrip('\n')
                fl = ftp.confs.add()
                for k in pwd.getpwall():
                    if user == k[0]:
                        fl.anonuser = k[0]

                        if k[5].find(self.dayu_mp) == 0:
                            fl.dir = k[5].split(self.dayu_mp)[1]
                        else:
                            fl.dir = k[5]

                        if servers == 'all':
                            res, hosts = usermgmt.dayuusermgmt.loadHost(self)
                            if not res:
                                return res, hosts
                        else:
                            hosts = servers.split(' ')

                        for k in hosts:
                            fl.servers.append(k)

                        str1 = ftp.SerializeToString()

                    if user == 'anonymous' and k[0] == 'ftp':
                        fl.anonuser = 'anonymous'
                
                        if k[5].find(self.dayu_mp) == 0:
                            fl.dir = k[5].split(self.dayu_mp)[1]
                        else:
                            fl.dir = k[5]

                        if servers == 'all':
                            res, hosts = usermgmt.dayuusermgmt.loadHost(self)
                            if not res:
                                return res, hosts
                        else:
                            hosts = servers.split(' ')

                        for k in hosts:
                            fl.servers.append(k)

                        str1 = ftp.SerializeToString()

            f.write(str1)
            f.close()
        return True, 'Done'

    def Search_Nfs_Original_Records(self):
        if not os.path.exists('/usr/local/dayu/python/NFS_list'):
            return True, 'Not find NFS_list'

        with open('/usr/local/dayu/python/NFS_list') as f:
            line = ''
            for i in f.readlines():
                line += i 
            f.close()
        
        if len(line) == 0:
            return True, ''
        line = line.split('host = ')

        nfs = usermgmt_pb2.NFSList()
        fsidarry = []
        with open(self.nfs_fn, 'r+') as fn:
            for i in line:
                if i == '':
                    continue

                record = i.split('\n')
                dayu_nfs = nfs.confs.add()
                
                for j in record:
                    if j.startswith('/'):
                        if len(j.split(',')) != 8:
                            return False, 'The record length of the wrong: %s' % j
                        info = j.split(' ')

                        for k in info:
                            if k.startswith('/'):
                                if k.find(self.dayu_mp) == 0:
                                    dayu_nfs.dir = k.split(self.dayu_mp)[1]
                                else:
                                    dayu_nfs.dir = k
                            
                            else:
                                dayu_nfs.clients = k.split('(')[0]
                                
                                if k.split(',')[1] == 'rw':
                                    dayu_nfs.rw = 'rw'
                                else:
                                    dayu_nfs.rw = 'ro'
                                
                                u = usermgmt_pb2.User()
                                u.uid = int(k.split(',')[4].split('=')[1])
                                res, msg = usermgmt.dayuusermgmt.Initialization(self)

                                res, user = usermgmt.dayuusermgmt.IdToName(self, 'User', u)
                                if not res:
                                    return res, user
                                dayu_nfs.user = user

                                u.gid = int(k.split(',')[5].split('=')[1])
                                res, group = usermgmt.dayuusermgmt.IdToName(self, 'Group', u)
                                if not res:
                                    return res, group
                                dayu_nfs.group = group

                                dayu_nfs.fsid = int(k.split(')')[0].split('=')[-1]) 
                                fsidarry.append(dayu_nfs.fsid)

                    else:
                        if j == 'all':
                            res, hosts = usermgmt.dayuusermgmt.loadHost(self)
                            if not res:
                                return res, hosts
                        else:
                            hosts = j.split(' ')

                        for k in hosts:
                            if k == '':
                                continue
                            else:
                                dayu_nfs.servers.append(k)

                str1 = nfs.SerializeToString()
            fn.write(str1)
            fn.close()

        fsid = max(fsidarry) + 1
        xattr.xattr(self.dir).set('FSID', '%d' % fsid)

        return True, 'Done'

def usage():
    print '''\
Search old data from /etc/passwd, ./UserPwd ./NFS_list ./CIFS_list ./NFS_list to DayuFileSystem

Allow options:
-h [--help]      Show the help message
-c  arg             Available commands:
                    all     Search all data
                    user    Search user, group
                    cifs    Search cifs
                    nfs     Search nfs
                    ftp     Search ftp'''
    sys.exit(1)

if __name__ == '__main__':
    opts, augs = getopt.getopt(sys.argv[1:],"hc:",["command", "help"])
    for op, value in opts:
        if op == "-c" or op == "--commands":
            cmd = value
        if op == "-h" or op == "--help":
            usage()

    a = collect()
    res, msg = a.initialization()
    if not res:
        sys.exit('%s: %s' % (res, msg))

    if 'cmd' not in locals().keys() or cmd not in ['all', 'user', 'cifs', 'nfs', 'ftp']:
        sys.exit('Lack of -c parameters')

    if cmd == 'all':
        res, msg = a.Store_The_Original_User()
        if not res:
            sys.exit('%s: %s' % (res, msg))
      
        res, msg = a.Search_CIFS_Original_Records()
        if not res:
            sys.exit('%s: %s' % (res, msg))
          
        res, msg = a.Search_Ftp_Original_Records()
        if not res:
            sys.exit('%s: %s' % (res, msg))
          
        res, msg = a.Search_Nfs_Original_Records()
        if not res:
            sys.exit('%s: %s' % (res, msg))

    elif cmd == 'user':
        res, msg = a.Store_The_Original_User()
        if not res:
            sys.exit('%s: %s' % (res, msg))
      
    elif cmd == 'cifs':
        if not os.path.isfile('./CIFS_list'):
            sys.exit('No such file CIFS_list')
        
        res, msg = a.Search_CIFS_Original_Records()
        if not res:
            sys.exit('%s: %s' % (res, msg))
          
    elif cmd == 'nfs':
        if not os.path.isfile('./NFS_list'):
            sys.exit('No such file NFS_list')
        
        res, msg = a.Search_Nfs_Original_Records()
        if not res:
            sys.exit('%s: %s' % (res, msg))
          
    else:        
        if not os.path.isfile('./FTP_list'):
            sys.exit('No such file NFS_list')
        
        res, msg = a.Search_Ftp_Original_Records()
        if not res:
            sys.exit('%s: %s' % (res, msg))
          
    print 'Finish'
