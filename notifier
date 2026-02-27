#!/bin/python3

import sys
import requests

BASEURL='https://api.telegram.org/bot'
BOT='BOTTOKEN'
CHID='CHANNELID'


headers = {
    'Content-Type': 'application/json',
    'Cache-Control': 'no-cache',
}

def sendMsg(msg):
    uri = BASEURL+BOT+'/sendMessage'
    data = {"chat_id":CHID,"text":msg}
    return requests.post(uri,headers=headers,json=data)

def main():
    if len(sys.argv) < 2:
        exit(1)

    for arg in sys.argv[1:]:
        res = sendMsg(arg)
        if res.status_code != 200:
            print(res.json().description)

if __name__== "__main__" :
     main()
