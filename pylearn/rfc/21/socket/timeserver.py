#!/usr/bin/env python
# -*- coding:UTF-8 -*-

from socket import *
import time

s = socket(AF_INET,SOCK_STREAM)
s.bind(("",8888))
s.listen(5)

while True:
    client, addr = s.accept()
    print("Got a connection from %s" % str(addr))
    timestr = time.ctime(time.time()) + "\r\n"
    client.send(timestr.encode('ascii'))
    client.close()

