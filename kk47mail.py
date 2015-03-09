#!/usr/bin/env python
# use dayu count to send mail

import smtplib
import getopt
import sys
import os
import datetime

def dayumail(para, mailto=[]):
   
    options = para.strip('\'').split('|||')
    if len(options) != 4:
        msg = 'Invalid alert format'
        return False, msg
    if "@]" in options[1]:
        options[1] = options[1].split(']',1)[0] + eenvid + options[1].split(']',1)[1]

    date = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
    
    header = ("From: %s\r\nTo: %s\r\nSubject: %s\r\n\r\n" % (mailuser, ','.join(mailto), options[1].strip()))
    body = ("Subject: %s\r\nLevel: %s\r\nDate: %s\r\n" % (options[1].strip(), options[0].strip(), date))
    body += ("Action: %s\r\nDescription: \r\n%s\r\n" % (options[2].strip(), options[3].strip()))

    # write to alert log 
    with open(alertlog, 'ab') as f:
        f.write('\n\n')
        f.write(header)
        f.write(body)
        f.write('\n\n')

    if alertmail.lower() == 'false':
        msg = "alert mail is disable, do nothing"
        return False, msg
    if len(mailto) == 0:
        msg = "none mail recipients given"
        return False, msg

    try:
        server = smtplib.SMTP(mailhub)
        server.login(mailuser, mailpwd)
        server.sendmail(mailuser, mailto, header + body)
        server.quit()
    except Exception, e:
        msg = 'Send alert email:%s' % str(e.message)
        return False, msg
    return True, ''
         
def usage():
    u = '''
    Name:
        %s - dayu email send scripts, act as a command.

    Synopsis:
        %s [-h]

    Description:
        Arguments are as following:
            -h      print the help message
            -p      content of the mail to send
            -m      email address to send mail
    Example:
        python %s -p "INFO|||Smoething|||Nothing|||Just a test" -m "test1@test.com test2@test.com"
    '''
    prog = os.path.basename(sys.argv[0])
    print u % (prog, prog, prog)

if __name__ == "__main__":
    try:
        opts,args = getopt.getopt(sys.argv[1:], "hp:m:")
    except getopt.GetoptError, msg:
        print msg
        sys.exit(1)

    para = ''
    mailto = [] 
    alertmail = 'false'
    alertlog = '/var/log/dayu/alert.log'
    nodecfg = '/var/local/dayu/nodes.cfg'

    try:
        f = open(nodecfg, 'r+')
        lines = f.readlines()
        f.close()
    except IOError:
        sys.exit(1)

    for line in lines:
        if line.startswith('EMAIL_ALERT'):
            vec = line.split('=')
            if len(vec) != 2 :
                continue
            alertmail = vec[1].strip()
            continue            
        if line.startswith('eenvid'):
            vec = line.split('=')
            if len(vec) != 2 :
                continue
            eenvid = vec[1].strip()
            continue            
        if line.startswith('SEND_ALERT_TO'):
            vec = line.split('=')
            if len(vec) != 2 :
                continue
            mailto = vec[1].strip().split()
            continue            
        if line.startswith("EMAIL_HUB"):
            vec = line.split('=')
            if len(vec) != 2 :
                continue
            mailhub = vec[1].strip()
            continue
        if line.startswith('EMAIL_USER'):
            vec = line.split('=')
            if len(vec) != 2 :
                continue
            mailuser = vec[1].strip()
            continue
        if line.startswith('EMAIL_PWD'):
            vec = line.split('=')
            if len(vec) != 2 :
                continue
            mailpwd = vec[1].strip()
            continue            

    for opt, value in opts:
        if opt == "-h":
            usage()
            sys.exit(0)
        elif opt == "-p":
            para = value
        elif opt == "-m":
            if len(value.strip()) != 0:
                mailto = value.strip().split()
        else:
            print "Wrong options!"
            sys.exit(1)

    if para != "" and mailuser != "" and mailhub != "" and mailpwd != "":
        res, msg = dayumail(para, mailto)
        if not res:
            print msg
            sys.exit(1)
    else:
        print "Wrong parameter"
        sys.exit(1)
