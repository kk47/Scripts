#! /usr/bin/env python 

import fcntl
import os
import sys
import getopt
import commands

def Check(id):
    sequnce = []
    try:
        with open(CronFile) as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            for i in f.readlines():
                sequnce.append(i)
            fcntl.flock(f, fcntl.LOCK_UN)
            f.close()
    except Exception, msg:
        return False, msg

    sequnce1 = []
    [sequnce1.append(i.split('\n')[0].split(' ')[-1]) for i in sequnce]
    
    for i in sequnce1:
        if i.find(str(id)) == 0:
            return True, 'Exist'

    return False, 'Not find'

def Create(cmd, id, nodes):
    res, msg = Check(id)
    if res:
        return False, 'Cron record already exist'

    try:
        with open(CronFile, 'a+') as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            f.write(cmd)
            fcntl.flock(f, fcntl.LOCK_UN)
            f.close()
    except Exception, msg:
        return False, msg

    'create new plugins on /etc/munin/plugins'
    content="""\
#!/bin/bash
# -*- sh -*-

. $MUNIN_LIBDIR/plugins/plugin.sh
. /etc/dayu/env.sh

if [ \"$1\" = \"autoconf\" ]; then
	echo yes
	exit 0
fi

if [ \"$1\" = \"config\" ]; then
    echo 'graph_title Directory Usage'
    echo 'graph_args --base 1000 -l 0'
    echo 'graph_vlabel Usage'
    echo 'graph_scale no'
    echo 'graph_category dayu'

    echo 'du_%s_total.label Usage'

    echo 'graph_info CMS Directory Usage'
    echo 'du_%s_total.info 5 minute average Usage of CMS'

    exit 0
fi

pidfile=\"/var/run/dayuds.pid\"
if [[ ! -f \"$pidfile\" ]]; then
    echo \"du_%s_total.value 0\"
    exit 0
fi

cmd=\"$DAYU_INSTALL_DIR/python/dirusage.py -c GetDirUsage -i %s\"
tmpfile=\"/tmp/dirusage_%s.munin\"

$cmd > $tmpfile
if [[ $? -ne 0 ]]; then
    echo \"failed to get %s DirUsage\" 
    exit 0
fi

du_%s_total=$(awk '{print $2}' $tmpfile)
if [[ -n \"$du_%s_total\" ]]; then
    echo -n \"du_%s_total.value \"
    echo \"$du_%s_total\"
fi""" % (id, id, id, id, id, id, id, id, id, id)

    try:
        with open('/etc/munin/plugins/dirusage_%s' % id, 'w') as f:
            f.write(content)
            f.close()
        os.chmod('/etc/munin/plugins/dirusage_%s' % id, 0777)
    except Exception, msg:
        return False, msg
            
    nodes = nodes.split(' ')
    hosts = ''
    if len(nodes) == 1:
        hosts += '%s:dirusage_%s.du_%s_total %s:dirusage_%s.du_%s_total ' % (nodes[0], id, id, nodes[0], id, id)
    else:
        for i in nodes:
            hosts += '%s:dirusage_%s.du_%s_total ' % (i, id, id)
    hosts = hosts.rstrip(' ')

    munin_content = """
    cluster_du_%s.graph_title Directory Usage
    cluster_du_%s.graph_category dayu
    cluster_du_%s.graph_scale yes
    cluster_du_%s.graph_order du_total
    cluster_du_%s.graph_args --base 1000 -l 0
    cluster_du_%s.du_%s_total.label Total
    cluster_du_%s.du_%s_total.sum %s\n""" % (id, id, id, id, id, id, id, id, id, hosts)

    try:
        with open('/etc/munin/munin.conf', 'a+') as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            f.write(munin_content)
            fcntl.flock(f, fcntl.LOCK_UN)
            f.close()
    except Exception, msg:
        return False, msg

    res, msg = commands.getstatusoutput('/etc/init.d/munin-node restart')
    if res != 0:
        return False, msg

    return True, 'Done'

def Change(key, cmd, id):
    res, msg = Check(id)
    if not res:
        return False, 'Cron record not find'

    try:
        sequnce1 = []
        sequnce2 = []
        str1 = ''
        find = False
        with open(CronFile, 'r+') as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            [sequnce1.append(i) for i in f.readlines()]

            for j in sequnce1:
                sequnce2 = j.split('\n')[0].split(' ')
                Id = sequnce2[11]
                if Id == id:
                    find = True
                    if key == 'edit':
                        str1 += cmd
                else:
                    str1 += j

            if not find:
                fcntl.flock(f, fcntl.LOCK_UN)
                return False, 'Cron job not exists, Please Check /etc/cron.d/dirusage'

            f.seek(0)
            f.truncate()
            f.write(str1)
            fcntl.flock(f, fcntl.LOCK_UN)
            f.close()
    except Exception, e:
        return False, 'Change Cron job Error, %s' % e

    if key == 'del':
        try:
            os.remove('/etc/munin/plugins/dirusage_%s' % id)

            with open('/etc/munin/munin.conf', 'r+') as f:
                fcntl.flock(f, fcntl.LOCK_EX)
                content = []
                [content.append(i) for i in f.readlines()]
                remove = False

                start = 0
                end = 0
                for i in xrange(len(content)):
                    if not remove:
                        if content[i] == '    cluster_du_%s.graph_title Directory Usage\n' % id:
                            remove = True
                            start = i
                    else:
                        if content[i].find('Directory Usage\n') != -1:
                            break
                        end = i

                length = end - start + 2
                start -= 1
                for j in xrange(length):
                    del content[start]

                str1 = ''
                for k in content:
                    str1 += k

                f.seek(0)
                f.truncate()
                f.write(str1)
                fcntl.flock(f, fcntl.LOCK_UN)
                f.close()
        except Exception, msg:
            return False, msg

        res, msg = commands.getstatusoutput('/etc/init.d/munin-node restart')
        if res != 0:
            return False, msg

    return True, 'Done'

def usage():
    print """version 1.0
    """
    sys.exit(1)

if __name__ == '__main__':
    global CronFile
    CronFile = '/etc/cron.d/dirusage'

    opts, augs = getopt.getopt(sys.argv[1:],"hc:p:i:n:",["help", "?"])
    for op, value in opts:
        if op == "-c":
            cmd = value
        if op == "-p":
            command = value
        if op == "-i":
            id = value
        if op == "-n":
            nodes = value
        if op == "-h":
            usage()

    if 'cmd' not in locals().keys() or cmd not in ['create', 'edit', 'del']:
        sys.exit('Lack of -c parameters')

    if 'id' not in locals().keys():
        sys.exit('Lack of -i parameters')

    if cmd == 'create':
        if 'command' not in locals().keys():
            sys.exit('Lack of -p parameters')

        if 'nodes' not in locals().keys():
            sys.exit('Lack of -n parameters')

        res, msg = Create(command, id, nodes)
        if not res:
            sys.exit(msg)

    elif cmd == 'edit':
        if 'command' not in locals().keys():
            sys.exit('Lack of -p parameters')

        res, msg = Change('edit', command, id)
        if not res:
            sys.exit(msg)

    else:
        command = ''
        res, msg = Change('del', command, id)
        if not res:
            sys.exit(msg)

    sys.exit(0)
