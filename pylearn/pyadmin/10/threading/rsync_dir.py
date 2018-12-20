#! /usr/bin/env python
# -*- coding:UTF-8 -*-
# 目录同步，感觉还可以进一步扩展

from threading import Timer
import sys
import time
import copy
import os
from subprocess import call


class EventLoopDelaySpawn(object):

    def __init__(self, poll=10, wait=1, verbose=True, dir1='/tmp/dir1', dir2='/tmp/dir2'):
        self.poll = int(poll)
        self.wait = int(wait)
        self.verbose = verbose
        self.dir1 = dir1
        self.dir2 = dir2

    def poller(self):
        time.sleep(self.poll)
        if self.verbose:
            print "Polling at %s sec interval" % self.poll

    def action(self):
        if self.verbose:
            print "waiting %s seconds to run Action" % self.wait
        ret = call("rsync -av --delete %s/ %s" % (self.dir1, self.dir2), shell=True)

    def event_handler(self):
        if os.listdir(self.dir1) != os.listdir(self.dir2): # 这样比较只能本地, 自定义协议
            print os.listdir(self.dir1)
            t = Timer((self.wait), self.action) # 其实不延迟也可以
            t.start()
            if self.verbose:
                print "Event Registered"
        else:
            if self.verbose:
                print "No Event Registered"

    def run(self):
        try:
            while True:
                self.event_handler()
                self.poller()
        except Exception as err:
            print "Error: %s" % err
        finally:
            sys.exit(0)

E = EventLoopDelaySpawn()
E.run()
