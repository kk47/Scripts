#!/usr/bin/env python
# -*- coding: utf-8 -*-

import urllib
import urllib2
import json
import sys
import os
import getopt
reload(sys)
sys.setdefaultencoding( "utf-8" )

class WeChat(object): 
    __token_id = ''
    # init attribute
    def __init__(self,url):
        self.__url = url.rstrip('/')
        self.__corpid = 'wx780eb49f4b171fc1'
        self.__secret = 'W67l6Ybu_NUcY7HoOBb8ftb7-SrJ-lH-xp6uwyPg6TGWaiJQH5HCfNh2nelaKPfw'

    # Get TokenID
    def authID(self):
        params = {'corpid':self.__corpid, 'corpsecret':self.__secret}
        data = urllib.urlencode(params)

        content = self.getToken(data)

        try:
            self.__token_id = content['access_token']
            # print content['access_token']
        except KeyError:
            raise KeyError

    # Establish a connection
    def getToken(self,data,url_prefix='/'):
        url = self.__url + url_prefix + 'gettoken?'
        try:
            response = urllib2.Request(url + data)
        except KeyError:
            raise KeyError
        result = urllib2.urlopen(response)
        content = json.loads(result.read())
        return content

    # Get sendmessage url
    def postData(self,data,url_prefix='/'):
        url = self.__url + url_prefix + 'message/send?access_token=%s' % self.__token_id
        request = urllib2.Request(url,data)
        try:
            result = urllib2.urlopen(request)
        except urllib2.HTTPError as e:
            if hasattr(e,'reason'):
                print 'reason',e.reason
            elif hasattr(e,'code'):
                print 'code',e.code
            return None 

        content = json.loads(result.read())
        result.close()
        return content

    # send message
    def sendMessage(self,touser,message):

        self.authID()

        data = json.dumps({
            'touser':touser,
            'msgtype':"text",
            'agentid':"1",
            'text':{
                'content':message
            },
            'safe':"0"
        },ensure_ascii=False)

        response = self.postData(data)
        print response


def usage():
    u = '''
    Name:
        %s - dayu wechat alert message send interface

    Synopsis:
        %s [-h] [-u] [-s]
    Description:
        Arguments are as following
            -h  print this help message
            -p  user to send
            -s  alert message to send
    '''
    prog = os.path.basename(sys.argv[0])
    print u % (prog, prog)
    sys.exit(0)

if __name__ == '__main__':
    
    try:
        opts, args = getopt.getopt(sys.argv[1:], 'hp:s:', "help")
    except getopt.GetoptError as e:
        print e
        sys.exit(1)
    
    for op, value in opts:
        if op in ("-h", "--help"):
            usage()
        elif op == "-p":
            print value
            touser = '|'.join(value.strip().split())
        elif op == "-s":
            message = value
        else:
            usage()

    a = WeChat('https://qyapi.weixin.qq.com/cgi-bin')
    a.sendMessage(touser, message)
