#! /usr/bin/env python
# -*-coding:UTF-8 -*-
# ftp客户端，未经过测试

from ftplib import FTP
import ftplib
import sys
from optparse import OptionParser

parser = OptionParser()

parser.add_option(
    '-a', '--remote_host_address', dest='remote_host_address',
    help='REMOTE FTP HOST.',
    metavar='REMOTE FTP HOST'
)
parser.add_option(
    '-r', '--remote_file', dest='remote_file',
    help='REMOTE FILE NAME to download',
    metavar='REMOTE FILE NAME'
)
parser.add_option(
    '-l', '--local_file', dest='local_file',
    help='LOCAL FILE NAME to save remote file to',
    metavar='LOCAL FILE NAME'
)
parser.add_option(
    '-u', '--username', dest='username',
    help='USERNAME for ftp server',
    metavar='USERNAME'
    )
parser.add_option(
    '-p', '--password', dest='password',
    help='PASSWORD for ftp server',
    metavar='PASSWORD'
)

(options, args) = parser.parse_args()

ftp = FTP(options.remote_host_address)
if options.username:
    try:
        ftp.login(options.username, options.password)
    except ftplib.error_perm as e:
        print 'Login failed: %s' % e
        sys.exit(1)
else:
    try:
        ftp.login()
    except ftplib.error_perm as e:
        print 'Anonymous login failed: %s' % e
        sys.exit(1)

try:
    local_file = open(options.local_file, 'wb')
    ftp.retrbinary('RETR %s' % options.remote_file, local_file.write)
finally:
    local_file.close()
    ftp.close()
