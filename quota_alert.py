#!/usr/bin/env python
# check quota usage and send alert message
# to run this scripts in cron job , you have to add PYTHONPATH=$PYTHONPATH:/usr/local/dayu/python/ in crontab

import os
import socket
import types_pb2
import commands
from alertmgmt import SendAlert

def quotaCheck():

    qlist = types_pb2.QuotaList()
    qcmd = dayu_instatll_dir + '/bin/dayuquota'
    cmd = qcmd + ' -c ListQuota'
    status, output = commands.getstatusoutput(cmd)
    if status != 0 :
        return False, output
    else :
        if len(output) > 0 :
            qlist.ParseFromString(output)
        else:
            msg = 'No quota dir exists.'
            return False, msg
    for q in qlist.quota:
        if q.alert == 'Y':
            if q.alert_percent:
                percent =  int(q.used * 100 / ( q.quota * 1024 * 1024 * 1024 ))
                if percent >= int(q.alert_percent):
                    subject = 'quota dir ' + q.path + ' used ' + str(percent) + '%'
                    desc = 'Usage is close to quota ' + str(q.quota) + 'G'
                    para = 'WARNING|||' + subject + '|||Please check|||' + desc 
                    res, msg = quotaAlert(para)
                    if not res:
                        return False, msg
                    mark = 'Y'
                else:
                    mark = 'N'
            elif q.alert_remain:
                used = float(q.used) / ( 1024 * 1024 * 1024 )
                remain = q.quota - used 
                if remain <= float(q.alert_remain):
                    remain = str(remain)
                    if "." in remain:
                        remain = remain.split(".")[0] + "." + remain.split(".")[1][:3]
                    subject = 'quota dir ' + q.path + ' only remain ' + remain + 'G'
                    desc = 'Usage is close to quota ' + str(q.quota) + 'G'
                    para = 'WARNING|||' + subject + '|||Please check|||' + desc 
                    res, msg = quotaAlert(para)
                    if not res:
                        return False, msg
                    mark = 'Y'
                else:
                    mark = 'N'
            else:
                pass

            '''change the alerted flag in quota protobuf , if alerted , change it to 'Y' , when the usage is 
            below quota , change it to 'N'.'''
            if q.alerted != mark:
                qstr = q.SerializeToString()
                qcmd = dayu_instatll_dir + '/bin/dayuquota'
                cmd = qcmd + ' -c UpdateQuota -i ' + qstr 
                status, output = commands.getstatusoutput(cmd)
                if status != 0 :
                    return False, output
    return True, ''

def quotaAlert(para):
    
    logfile = '/tmp/quota_alert.log'
    if not os.path.exists(logfile):
        os.mknod(logfile)
    try:
        with open(logfile, 'r+') as f:
            for line in f:
                if para in line:
                    return True, ''
                else:
                    para = para + '\n'
            f.write(para)
    except OSError, e:
        return False, e.message
        
    sa = SendAlert()
    res, msg = sa.send(para)
    if not res:
        msg = "send quota alert failed."
        return False, msg
    
    return True, ''
    
if __name__ == "__main__":

    dayu_instatll_dir = '/usr/local/dayu/'
    if 'DAYU_INSTALL_DIR' in os.environ:
        dayu_instatll_dir = os.environ['DAYU_INSTALL_DIR']

    res, msg = quotaCheck()
    if not res:
        print msg
