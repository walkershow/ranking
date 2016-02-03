#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Author: coldplay
# @Date:   2016-02-02 11:10:40
# @Last Modified by:   coldplay
# @Last Modified time: 2016-02-02 14:31:05
import os
import sys
from fdfs_client.client import *
import optparse
import logging
import logging.config
import dbutil
import json
f_client = None
def init():
	parser = optparse.OptionParser()


	parser.add_option("-q", "--ip2", dest="db_ip2", default="192.168.1.183",
			help="mysql database server IP address, default is 192.168.1.183" )
	parser.add_option("-r", "--name2", dest="db_name2", default="gm_data",
			help="database name, default is gm_data" )
	parser.add_option("-z", "--username2", dest="username2", default="dev",
			help="database login username, default is root" )
	parser.add_option("-t", "--password2", dest="password2", default="123",
			help="database login password, default is 123456" )
	parser.add_option("-v", "--db_port2", dest="db_port2", default="3306",
			help="mysql server port, default is 3306" )
	parser.add_option("-e", "--db_charset", dest="db_charset", default="utf8",
			help="mysql charset, default is utf8" )

	parser.add_option("-l", "--logconf", dest="logconf", default="./d_ranking.log.conf",
			help="log config file, default is ./d_ranking.log.conf" )
	parser.add_option("-s", "--sleep_time", dest="sleep_time", default="10",
			help="the directory to scan, default is 10" )
	(options, args) = parser.parse_args()

	if not os.path.exists(options.logconf):
		print 'no exist:', options.logconf
		sys.exit(1)
	logging.config.fileConfig(options.logconf)
	global logger
	logger = logging.getLogger()
	logger.info( options )

	global sleep_time
	sleep_time = int(options.sleep_time)

	dbutil.db_host = options.db_ip2
	dbutil.db_name = options.db_name2
	dbutil.db_user = options.username2
	dbutil.db_pwd = options.password2
	dbutil.db_port = int(options.db_port2)
	dbutil.db_charset = options.db_charset

	dbutil.logger = logger

def del_rankingpic(picdict):
	print "del_rankingpic:",picdict
	if picdict is None:
		return
	for k in picdict.keys():
		logger.info("delete file:%s", picdict[k])
		try:
			ret = f_client.delete_file(picdict[k].encode('ascii'))
		except:
			logger.error('exception', exc_info = True)

def main():
	global	f_client
	init()
	# init_fortest()
	f_client = Fdfs_client('/etc/fdfs/client.conf')
	# p = re.compile("装备")
	# if p.match("装备.txt"):
	# 	print "hihiddddddddddddd"

	# bf = BlockFormatter(fmtconf)
	# bf.Formmating(dfile, ofile)
	logger.info( "begin......" )
	del_sql = "delete from PIC_TEMP where id=%d"
	while 1:
		sql = "select ID,PICURL from PIC_TEMP"
		# logger.debug( "sql:%s"%(sql) )
		rows = dbutil.select_sql(sql)
		if rows is None or len(rows)<=0:
			logger.error("no talbe to locate")
			continue
		for row in rows:
			# print row[1]
			pic_dict = json.loads(row[1])
			# print pic_dict
			del_rankingpic( pic_dict )
			del_s = del_sql%(row[0])
			print del_s
			dbutil.execute_sql(del_s)
		time.sleep( sleep_time )

	logger.info( "end!!!!!!" )
	# scan("./", fmtconfdir)


if __name__ == "__main__":
	main()
