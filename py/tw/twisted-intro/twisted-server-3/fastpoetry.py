# -*- coding:utf-8 -*-
# 使用twist服务的版本, 主要的tac文件,应用配置文件
# This is the Twisted Fast Poetry Server, version 2.0

from twisted.application import internet, service
from twisted.internet.protocol import ServerFactory, Protocol
from twisted.python import log

# Normally we would import these classes from another module.


class PoetryProtocol(Protocol):
    def connectionMade(self):
        poem = self.factory.service.poem
        log.msg(
            "sending %d bytes of poetry to %s" % (len(poem), self.transport.getPeer())
        )
        self.transport.write(poem)
        self.transport.loseConnection()


class PoetryFactory(ServerFactory):

    protocol = PoetryProtocol

    def __init__(self, service):
        self.service = service


class PoetryService(service.Service):  # 仅仅加载诗歌以及为其他需要诗歌的对象提供接口
    def __init__(self, poetry_file):
        self.poetry_file = poetry_file

    def startService(self):
        service.Service.startService(self)
        self.poem = open(self.poetry_file).read()
        log.msg("loaded a poem from: %s" % (self.poetry_file,))


#####################################################################
##
## 接下来是应用的组织结构
##
#####################################################################

# configuration parameters   # 配置文件
port = 10000
iface = "localhost"
poetry_file = "poetry/ecstasy.txt"

# this will hold the services that combine to form the poetry server
top_service = service.MultiService()

# the poetry service holds the poem. it will load the poem when it is
# started
poetry_service = PoetryService(poetry_file)
poetry_service.setServiceParent(top_service)

# the tcp service connects the factory to a listening socket. it will
# create the listening socket when it is started
factory = PoetryFactory(poetry_service)
tcp_service = internet.TCPServer(port, factory, interface=iface)
tcp_service.setServiceParent(top_service)

# this variable has to be named 'application'
application = service.Application("fastpoetry")

# this hooks the collection we made to the application
top_service.setServiceParent(application)

# at this point, the application is ready to go. when started by
# twistd it will start the child services, thus starting up the
# poetry server