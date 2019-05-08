#! /usr/bin/env python
# -*- coding:UTF-8 -*-
# 基于httplib的Web服务器检测

import httplib
import sys

def check_webserver(address, port, resource):
    if not resource.startswith("/"):    # 构造请求
        resource = "/" + resource

    try:
        conn = httplib.HTTPConnection(address, port)
        print 'HTTP connection created successfully'

        req = conn.request('GET', resource)
        print 'request for %s successful' % resource

        response = conn.getresponse()
        print 'respose status: %s' % response.status

    except socket.error as e:
        print 'HTTP connection failed: %s' % e
        return False
    finally:
        conn.close()
        print 'HTTP connection closed successfully'

    if response.status in [200, 301]:
        return True
    else:
        return False


if __name__ == "__main__":
    from optparse import OptionParser
    parser = OptionParser()

    parser.add_option("-a", "--address", dest="address", default="localhost",
            help = "ADDRESS for server", metavar = "ADDRESS" )
    parser.add_option("-p", "--port", dest="port", type="int", default=80,
            help = "PORT for server", metavar = "PORT" )
    parser.add_option("-r", "--resource", dest="resource", default="index.html",
            help = "RESOURCE to check", metavar="RESOURCE")
    (options, args) = parser.parse_args()

    print "options: %s, args: %s" % (options, args)
    check = check_webserver(options.address, options.port, options.resource)
    print "check_server returned %s" % check
    sys.exit(not check) # 希望从shell脚本调用该方法
