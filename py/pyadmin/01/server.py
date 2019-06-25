#! /usr/bin/env python3
# -*-coding:UTF-8 -*-
# @Time    : 2019/06/13 10:47:31
# @Author  : che
# @Email   : ch1huizong@gmail.com


class Server(object):
    def __init__(self, ip, hostname):
        self.ip = ip
        self.hostname = hostname

    def set_ip(self, ip):
        self.ip = ip

    def set_hostname(self, hostname):
        self.hostname = hostname

    def ping(self, ip_addr):
        print('Pinging %s from %s (%s)' % (ip_addr, self.ip, self.hostname))


if __name__ == '__main__':
    server = Server('192.168.1.3', 'King')
    server.ping('192.168.1.10')
