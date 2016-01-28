#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Author: coldplay
# @Date:   2015-12-04 14:34:25
# @Last Modified by:   coldplay
# @Last Modified time: 2015-12-12 09:46:19

import os
import sys
import optparse
import time
import ConfigParser
import dbutil
import redis
import logging
import logging.config
from redis import exceptions

def init():
	parser = optparse.OptionParser()
	parser.add_option("-i", "--ip", dest="redis_ip", default="192.168.1.181",
			help="redis server IP address, default is 192.168.1.181" )
	parser.add_option("-p", "--redis_port", dest="redis_port", default="6379",
			help="redis server port, default is 6379" )
	parser.add_option("-n", "--redis_num", dest="redis_num", default="1",
			help="redis num, default is 0" )
	parser.add_option("-k", "--redis_key", dest="redis_key", default="gamedb",
			help="redis key, default is chinau_6a" )
	parser.add_option("-q", "--ip2", dest="db_ip2", default="192.168.2.14",
			help="database server IP address, default is 192.168.2.14" )
	parser.add_option("-r", "--name2", dest="db_name2", default="gamedb",
			help="database name, default is gm_data" )
	parser.add_option("-z", "--username2", dest="username2", default="dev",
			help="database login username, default is root" )
	parser.add_option("-t", "--password2", dest="password2", default="123",
			help="database login password, default is 123456" )
	parser.add_option("-v", "--db_port2", dest="db_port2", default="3306",
			help="mysql server port, default is 3306" )
	parser.add_option("-e", "--db_charset", dest="db_charset", default="utf8",
			help="mysql charset, default is utf8" )
	parser.add_option("-l", "--logconf", dest="logconf", default="./dealer_sql.log.conf",
			help="log config file, default is ./dealer_sql.log.conf" )
	(options, args) = parser.parse_args()

	if not os.path.exists(options.logconf):
		print 'no exist:', options.logconf
		sys.exit(1)
	logging.config.fileConfig(options.logconf)

	global redis_addr,redis_port,redis_num,redis_key
	redis_addr = options.redis_ip
	redis_port = options.redis_port
	redis_num = options.redis_num
	redis_key = options.redis_key

	global logger
	logger = logging.getLogger()
	logger.info( options )

	dbutil.db_host = options.db_ip2
	dbutil.db_name = options.db_name2
	dbutil.db_user = options.username2
	dbutil.db_pwd = options.password2
	dbutil.db_port = int(options.db_port2)
	dbutil.db_charset = options.db_charset

	dbutil.logger = logger

def main():
	init()
	r = redis.StrictRedis(host=redis_addr, port=redis_port, db=redis_num)
	if r is None:
		logger.error("redis connect failed")
		return
	result = None
	while True:
		try:
			result = r.brpop(redis_key)
			# print type(result[1])
			print result[1]
			dbutil.execute_sql(result[1])
		except exceptions.RedisError:
			logger.error('exception', exc_info = True)
			return


if __name__ == "__main__":
	main()
