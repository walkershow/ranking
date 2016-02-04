#!/usr/bin/env python
#coding=utf8

import os
import sys
import stat
import optparse
import time
import ConfigParser
import json
import re
import logging
import logging.config
from collections import OrderedDict
from cassandra.cluster import Cluster
from glob import glob
from fdfs_client.client import *
import dbutil
import re
import codecs
import signal

g_area = None
f_client = None
g_bquit = False

def scan(path, cur_dir, fmtconfdir):
	global g_area,g_bquit
	if os.path.isfile(path):
		if path.endswith('.txt'):
			print "path:",path
			diritems = path.split("/")
			if len(diritems)<4:
				logger.error("路径中不包含游戏名或游戏区号:%s",path)
			else:
				gameid = diritems[-3]
				if gameid.isdigit():
					gameid = int(gameid)
				else:
					logger.debug("游戏ID必须是数字:%s", gameid)
					return
				area = diritems[-2]
				if area.isdigit():
					g_area = int(area)
				else:
					logger.debug("区标识必须是数字:%s", area)
					return
				txt_dir = os.path.dirname(path)
				rename_cmd = "rename .jpg.j .jpg %s/*.j"%(txt_dir)
				print rename_cmd
				os.system(rename_cmd)
				filename = diritems[-1]

				fmtdiritems = ['/'.join(diritems[0:4]),diritems[3]+".conf"]
				fmtpath = '/'.join(fmtdiritems)
				print fmtpath
				if os.path.exists(fmtpath) == False:
					logger.debug("游戏配置文件不存在:%s", fmtpath)
					return

				if os.path.exists(fmtpath):
					logger.debug("gameid:%d", gameid)
					if gameid is None:
						logger.error("cannot find the  this game :%s", path)
					# continue
					else:
						bf = BlockFormatter( fmtpath )
						bf.Formmating2( path , gameid )
						logger.info("删除TXT文件，防止不断重复执行:%s", path)
						mv_cmd = "mv %s %s.bak"%(path,path)
						print mv_cmd
						os.system(mv_cmd)
						# os.remove(path)

				else:
					# logger.error("当前文件没有对应的配置文件：%s", path)
					logger.error("游戏配置文件不存在:%s", fmtpath)

	elif os.path.isdir(path):
		for item in os.listdir(path):
			if g_bquit:
				break
			itemsrc = os.path.join(path, item)
			# print 'itemsrc',itemsrc
			scan(itemsrc, path, fmtconfdir)
		#time.sleep(1)


class BlockFormatter:
	def __init__(self, jsonFile):
		print "jsonFile", jsonFile
		self.json_fp = open(jsonFile, 'r')
		content = self.json_fp.read()
		if content[:3] == codecs.BOM_UTF8:
			content = content[3:]
		self.origin_ranking_dict = json.loads(content)


	def Formmating2(self, dfile,  gameid):
			logger.info("=====================start handle file:%s======================"%(dfile))
			fp = open(dfile, "r")

			pattern = re.compile(r'^(\d+)-(\w+)')
			line_one = None
			ranking = None
			cur_ranking = None
			ranking_item = None
			cur_ranking_dict = OrderedDict()
			cur_dir =os.path.dirname(dfile)

			for line in fp:
				strip_line = line.rstrip()
				v_items = strip_line.split('|')
				match =re.match(pattern, v_items[0])
				data = {}
				if match:
					# print match.group(1,2)
					ranking, ranking_item = match.group(1,2)
					logger.info("=====================handle ranking:%s,ranking_item:%s======================"%(ranking,ranking_item))
					if cur_ranking is None:
						cur_ranking = ranking
					if ranking != cur_ranking:
						arr = [cur_ranking_dict]
						data["玩家信息"] = arr
						j = json.dumps(data)
						t=j.decode('unicode-escape')
						t.encode("utf8")
						logger.info("============Start Uploading ranking %s==============")
						Upload_data(cur_dir, cur_ranking, gameid, t)
						logger.info("============end Uploading ranking %s==============")

						cur_ranking = ranking

					ipos = 1
					if not self.origin_ranking_dict.has_key(ranking_item):
						logger.error("%s not exist in conf file"%(ranking_item))
						return
					for k in self.origin_ranking_dict[ranking_item].keys():
						cur_ranking_dict[k] = v_items[ipos]
						ipos = ipos + 1
			arr = [cur_ranking_dict]
			data["玩家信息"] = arr
			j = json.dumps(data)
			t=j.decode('unicode-escape')
			t.encode("utf8")
			logger.info("============Start Uploading ranking %s==============")
			Upload_data(cur_dir, cur_ranking, gameid, t)
			logger.info("============end Uploading ranking %s==============")
			logger.info("=====================end handle file:%s======================"%(dfile))


def init():
	parser = optparse.OptionParser()
	parser.add_option("-i", "--ip", dest="db_ip", default="192.168.1.222",
			help="cassandra database server IP address, default is 192.168.1.222" )
	parser.add_option("-n", "--name", dest="db_name", default="gamedb",
			help="database name, default is gamedb" )
	parser.add_option("-u", "--username", dest="username", default="chinau",
			help="database login username, default is chinau" )
	parser.add_option("-p", "--password", dest="password", default="123",
			help="database login password, default is 123" )
	parser.add_option("-q", "--ip2", dest="db_ip2", default="192.168.1.223",
			help="database server IP address, default is 192.168.1.223" )
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
	parser.add_option("-l", "--logconf", dest="logconf", default="./ranking.log.conf",
			help="log config file, default is ./ranking.log.conf" )
	parser.add_option("-d", "--direcotry", dest="dir", default="./",
			help="the directory to scan, default is ./" )
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
	global cluster
	ips = options.db_ip.split(',')
	print ips
	cluster = Cluster(ips)
	global session
	dbname = options.db_name
	print dbname
	session = cluster.connect(dbname)
	global scandir
	scandir = options.dir
	global sleep_time
	sleep_time = int(options.sleep_time)

	dbutil.db_host = options.db_ip2
	dbutil.db_name = options.db_name2
	dbutil.db_user = options.username2
	dbutil.db_pwd = options.password2
	dbutil.db_port = int(options.db_port2)
	dbutil.db_charset = options.db_charset

	dbutil.logger = logger


def init_fortest():
	parser = optparse.OptionParser()

	parser.add_option("-l", "--fmtconfdir", dest="fmtconfdir", default="./",
			help="game format config directory, default is ./fmtconfdir" )
	parser.add_option("-d", "--file", dest="file", default="test.txt",
			help="the directory to scan, default is test.txt" )
	parser.add_option("-o", "--outfile", dest="ofile", default="test.json",
			help="the directory to scan, default is test.json" )
	parser.add_option("-m", "--filematch", dest="filematch", default="./filematch.json",
			help="the directory to scan, default is filematch.json" )
	(options, args) = parser.parse_args()

	global fmtconfdir
	fmtconfdir = options.fmtconfdir
	global dfile
	dfile = options.file
	global ofile
	ofile = options.ofile
	global filematch
	filematch = options.filematch


def Upload_data(cur_dir, ranking, gameid, data ):
	piclist = get_rankingpic(ranking, cur_dir)

	pic_dict = OrderedDict()
	all_succ = True
	for p in piclist:
		logger.info( "upload %s", p)

		ret = f_client.upload_by_filename(p)
		if ret['Status'] == "Upload successed.":
			filename = os.path.basename(p)
			pic_dict[ filename ] = ret['Remote file_id']
			# print ret
		else:
			all_succ = False
			del_rankingpic(picdict)
			logger.error( "数据上传错误，回滚本次上传操作:%s", ret['Status'] )
			break
		# logger.info( "===========end upload ===============%s", p)
	# 过程未发生错误，才更新数据库
	if all_succ:
		pictxt = json.dumps(pic_dict)
		pictxt = pictxt.decode('unicode-escape')
		pictxt.encode('utf8')
		# print pictxt
		get_last_rankingpic2(gameid, g_area, ranking)

		handle_rankinglist2( gameid, g_area, ranking, data, pictxt)
		#入库成功后，删除本地图片
		# for p in piclist:
			# os.remove(p)


def del_rankingpic(picdict):
	if picdict is None:
		return
	for k in picdict.keys():
		logger.info("delete file:%s", picdict[k])
		try:
			ret = f_client.delete_file(picdict[k].encode('ascii'))
		except:
			logger.error('exception', exc_info = True)


def get_last_rankingpic2(gameid, area, ranking):
	logger.info("================= clear last_rankingpic ==================")
	ranking = int(ranking)
	cql = "SELECT picurl FROM gameranking WHERE gameid=? and ranking=? and area=?"
	cql_stmt = session.prepare(cql)
	logger.info( "cql:%s"%(cql) )
	rows = session.execute( cql_stmt, [gameid, ranking, area] )

	if len(rows.current_rows)<=0:
		return None
	picurl_data = rows[0][0]
	sql = "insert into PIC_TEMP(picurl) values('%s')"%(picurl_data)
	logger.info( "sql:%s"%(sql) )
	dbutil.execute_sql(sql)


def handle_rankinglist2( gameid, area, ranking, data, picurl):
	ranking = int(ranking)
	if ranking_exist(ranking, gameid, area) is True:
		ranking_update( ranking, gameid, area, data,picurl)
	else:
		cql = "insert into gameranking(ranking, gameid, area, data, picurl) values(?, ?, ?, ?, ?)"
		cql_stmt = session.prepare(cql)
		logger.debug( "cql:%s"%(cql) )
		session.execute( cql_stmt, [ranking, gameid, area, data.strip(), picurl] )


def ranking_update(ranking, gameid, area, data, picurl):
	logger.debug("update ranking")
	cql = "update gameranking set data=?, picurl=? where gameid=? and ranking=? and area=?"
	cql_stmt = session.prepare(cql)
	logger.debug( "cql:%s"%(cql) )
	session.execute( cql_stmt, [data.strip(), picurl, gameid, ranking, area] )


def ranking_exist( ranking, gameid, area):
	cql = "SELECT gameid FROM gameranking WHERE gameid=? and ranking=? and area=?"
	cql_stmt = session.prepare(cql)
	logger.info( "cql:%s"%(cql) )
	rows = session.execute( cql_stmt, [gameid, ranking, area] )
	if rows is None or len(rows.current_rows)<=0:
		return False
	return True


def search_file(pattern, search_path=os.environ['PATH'], pathsep=os.pathsep):
	for path in search_path.split(os.pathsep):
		for match in glob(os.path.join(path, pattern)):
			yield match


def get_rankingpic(ranking, search_path):
	print "get_rankingpic:",ranking
	pattern = ranking+"-*"
	matchs = list(search_file(pattern,search_path))
	return matchs

def onsignal_term(a,b):
	global	g_bquit
	g_bquit = True
	print '收到SIGTERM信号'

def main():
	global fmtconf,dfile, ofile,f_client,g_bquit
	init()
	signal.signal(signal.SIGTERM,onsignal_term)
	signal.signal(signal.SIGINT,onsignal_term)
	f_client = Fdfs_client('/etc/fdfs/client.conf')

	logger.info( "begin......" )

	while 1:
		if g_bquit:
			print "i'm quit"
			break
		try:
			scan(scandir,scandir, None)
		except:
			logger.error('exception', exc_info = True)
		finally:
			time.sleep( sleep_time )

	logger.info( "end!!!!!!" )
	# scan("./", fmtconfdir)


if __name__ == "__main__":
	main()
