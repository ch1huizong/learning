# -*- coding:utf-8 -*-
from twisted.internet import defer


def got_results(res):
    print "We got:", res


d1 = defer.Deferred()
d2 = defer.Deferred()
d = defer.DeferredList([d1, d2])  # 无consumeErrors选项
d.addCallback(got_results)

print "Firing d1."
d1.callback("d1 result")
print "Firing d2 with errback."
d2.errback(Exception("d2 failure"))
