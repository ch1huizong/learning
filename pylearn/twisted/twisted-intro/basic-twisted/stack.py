#! /usr/bin/env python
# -*- coding:UTF-8 -*-

import traceback

def stack():
    print 'The python stack:'
    traceback.print_stack()

from twisted.internet import reactor
reactor.callWhenRunning(stack)
reactor.run()