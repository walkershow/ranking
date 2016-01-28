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

g_area = None
f_client = None


def scan(path, cur_dir, fmtconfdir):
	global g_area
	if os.path.isfile(path):
		# path = path.lower()
		if path.endswith('.txt'):
			diritems = path.split("/")
			# print "items:",diritems
			if len(diritems)<4:
				logger.error("路径中不包含游戏名或游戏区号:%s",path)
			else:
				gameid = diritems[-3]
				if gameid.isdigit():
					gameid = int(gameid)
				else:
					return
				area = diritems[-2]
				if area.isdigit():
					g_area = int(area)
				else:
					return
				# g_area = area
				filename = diritems[-1]
				fmtconf = get_match_confile(diritems[-1])
				print 'gameid,area,filename, fmtconf', gameid, area, filename, fmtconf

				if fmtconf is not None:
					fmtconfpath = fmtconfdir + "/" + fmtconf

					# gameid = find_gametype2(gamename)
					logger.debug("gameid:%d", gameid)
					if gameid is None:
						logger.error("cannot find the  this game :%s", path)
					# continue
					else:
						bf = BlockFormatter( fmtconfpath )
						bf.Formmating( path , gameid )
						logger.info("删除TXT文件，防止不断重复执行:%s", path)
						os.remove(path)
						# handle_rankinglist(path, gametype, gameid, area)
						# os.rename(path, path+".done")

				else:
					# logger.error("当前文件没有对应的配置文件：%s", path)
					logger.error("当前文件没有对应的配置文件:%s",path)

	elif os.path.isdir(path):
		for item in os.listdir(path):
			itemsrc = os.path.join(path, item)
			# print 'itemsrc',itemsrc
			scan(itemsrc, path, fmtconfdir)
		#time.sleep(1)


class BlockFormatter:
	def __init__(self, iniConfFile):
		print "iniConfFile", iniConfFile
		self.cf = ConfigParser.ConfigParser()
		self.cf.read(iniConfFile)


	def init_iniconf(self):
		self.delimiter = self.cf.get("FORMAT_DEFINITION","block_delimiter")
		self.delimiter = self.format_delmiter(self.delimiter)
		self.line_delimiter = self.cf.get("FORMAT_DEFINITION","line_delimiter")
		self.line_delimiter = self.format_delmiter(self.line_delimiter)
		self.blines = self.cf.get("BLOCK","BLINES")
		self.bloop = self.cf.get("BLOCK","BLOOP")
		self.bdlms = self.cf.get("BLOCK","BDLMS")
		self.blfmt = self.cf.get("BLOCK","BLFMT")
		# keys  = self.cf.get("BLOCK","KEYS")
		# self.keys_lst = keys.split(",")
		keyjson  = self.cf.get("BLOCK","KEYS_TO_DBKEYS")
		# print keyjson
		self.keystodb_dict = json.loads(keyjson)
		# print self.keystodb_dict
		self.keys_dict = {}
		# print "key_dict:", self.keystodb_dict
		blines_name  = self.cf.get("BLOCK","BLINES_NAME")
		self.blines_namelst = blines_name.split(',')



	def format_delmiter(self, dlms):
		if dlms == "\\r\\n":
			return '\r\n'
		elif dlms == "\\n":
			return '\n'
		else:
			return dlms


	def get_txtpartinfo(self, dfile):
		fp = open(dfile, "r")
		text = fp.read()
		blocks = text.split(self.delimiter)
		return blocks


	def BlockToList(self, txt):
		logger.debug("#############BLOCKTOLIST start#################")

		logger.debug("txt:%s",txt)
		bls = self.blines.split(",")
		tlines = txt.split(self.line_delimiter)
		# print "tlines:",tlines
		curline,lastbls = 0, 0
		txtlist = []
		# for tl in tlines
		for i in range(0,len(bls)):
			# print curline, lastbls+int(bls[i])
			# print tlines[0:1]
			# print "i",int(bls[i])
			if(int(bls[i]) == -1):
				ls = tlines[curline:]
			else:
				ls = tlines[curline:lastbls+int(bls[i]) ]
			curline+=int(bls[i])
			lastbls += int(bls[i])
			txtlist.append(ls)
		# print txtlist
		logger.debug( "#############BLOCKTOLIST end#################" )

		return txtlist


	def line_format(self, line, tmp_lst,  curfm, curloop, curdls):
		try:
			blfm = self.blfmt.split("|")
			line_item = line.split(curdls)
			fm = curfm.split(',')
			line_itemcount= len(line_item)
			rawline_itemcount = line_itemcount
			fm_itemcount = len(fm)
			# print "fm,fm_count,rawline_itemcount", fm,fm_itemcount,rawline_itemcount

			if curloop==0 and fm_itemcount<line_itemcount:
				# print "reformat the line"
				line_item = line.split(curdls, fm_itemcount)
				line_itemcount= len(line_item)
				# print "new line item",line_item

			# print "line_itemcount,loop",line_itemcount, curloop

			if curloop>0:
				tmplst =[]
				tmpdict = OrderedDict()
				for j in range(0, line_itemcount, curloop):
					for k in range(0, curloop):
						if k+j >=  line_itemcount:
							break
						# print "k+j",k+j,line_item[k+j]
						tmpdict[ fm[k].decode('utf8') ] = line_item[k+j]
						if fm[k].decode('utf8') in self.keystodb_dict.keys():
							self.keys_dict[ self.keystodb_dict[ fm[k].decode('utf8') ] ] = tmpdict[ fm[k].decode('utf8') ]
					# print "tmpdict",tmpdict
					if len(tmpdict.keys()) >0:
						tmp_lst.append(tmpdict.copy())

			else:
				txtdict = OrderedDict()
				for j in range(0, fm_itemcount):
					if j== fm_itemcount-1 and rawline_itemcount> fm_itemcount:
						txtdict[ fm[j].decode('utf8') ] = line_item[ j: ]

					else:
						txtdict[ fm[j].decode('utf8') ] = line_item[ j ]
					if fm[j].decode('utf8') in self.keystodb_dict.keys():
							self.keys_dict[ self.keystodb_dict[ fm[j].decode('utf8') ] ] = txtdict[ fm[j].decode('utf8') ]
				# print "txtdict,", txtdict
				# print 'len(txtdict.keys())',len(txtdict.keys())
				if len(txtdict.keys()) >0:
					tmp_lst.append(txtdict.copy())
		except:
			logger.error('exception', exc_info = True)
			return False
		return True

			# print "tmp_lst", tmp_lst


	def block_format(self, txtlist):
		blps = self.bloop.split(",")
		bdls = self.bdlms.split(",")
		blfm = self.blfmt.split("|")
		txtlst_len = len(txtlist)
		print "txtlst_len", txtlst_len
		linedict={}
		for i in range(0, txtlst_len):
			curloop = int(blps[i])
			curdls = bdls[i]
			logger.debug( "curdls:%s",curdls)

			curfm = blfm[i]
			logger.debug(  "curfm:%s",curfm)
			# print txtlist
			txt_list = txtlist[i]
			print "cur_list",txt_list

			tmplst = []
			for tl in txt_list:
				logger.debug(  '#################################start hand line##############################')
				logger.debug( "curline",tl.decode("utf8") )
				if tl!="":
					if self.line_format(tl, tmplst, curfm, curloop, curdls) is False:
						continue
				logger.debug(  '#################################end hand line################################')
			# print 'len(tmplst)',len(tmplst)
			if len(tmplst)>0:
				linedict[ self.blines_namelst[i] ] = tmplst
		return linedict


	def Formmating(self, dfile,  gameid):
		self.init_iniconf()
		blocks = self.get_txtpartinfo( dfile)
		cur_dir =os.path.dirname(dfile)
		print "len of blocks", len(blocks)
		print "blocks", blocks
		print "##############################"
		for b in blocks:
			logger.debug(  "++++++++++++++++++++++++++++++start handle the block++++++++++++++++++")
			logger.debug(  "block content:%s",b)
			tmp = self.BlockToList(b.strip())
			logger.debug(  "tmp:%s", tmp)
			d = self.block_format(tmp)
			if len(d.keys())<=0:
				continue
			# print d
			logger.debug( "+============================+")
			j = json.dumps(d)
			t=j.decode('unicode-escape')
			t.encode("utf8")
			ranking = self.keys_dict["ranking"]
			piclist = get_rankingpic(ranking, cur_dir)

			pic_dict = OrderedDict()
			all_succ = True
			for p in piclist:
				ret = f_client.upload_by_filename(p)
				if ret['Status'] == "Upload successed.":
					filename = os.path.basename(p)
					pic_dict[ filename ] = ret['Remote file_id']
					print ret
				else:
					all_succ = False
					del_rankingpic(picdict)
					logger.error( "数据上传错误，回滚本次上传操作:%s", ret['Status'] )

					break
			# 过程未发生错误，才更新数据库
			if all_succ:
				pictxt = json.dumps(pic_dict)
				pictxt = pictxt.decode('unicode-escape')
				pictxt.encode('utf8')
				# print pictxt
				tmp_dict = get_last_rankingpic(gameid, self.keys_dict)
				# print "tmp_dict",tmp_dict
				del_rankingpic( tmp_dict )
				handle_rankinglist( gameid, self.keys_dict, t, pictxt)
				for p in piclist:
					os.remove(p)

			self.keys_dict.clear()



def init():
	parser = optparse.OptionParser()
	parser.add_option("-i", "--ip", dest="db_ip", default="192.168.1.12",
			help="database server IP address, default is 192.168.1.12" )
	parser.add_option("-n", "--name", dest="db_name", default="gamedb",
			help="database name, default is gamedb" )
	parser.add_option("-u", "--username", dest="username", default="chinau",
			help="database login username, default is chinau" )
	parser.add_option("-p", "--password", dest="password", default="123",
			help="database login password, default is 123" )

	parser.add_option("-q", "--ip2", dest="db_ip2", default="192.168.1.113",
			help="database server IP address, default is 192.168.1.113" )
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
	parser.add_option("-f", "--fmtconfdir", dest="fmtconfdir", default="./",
			help="game format config directory, default is ./fmtconfdir" )
	parser.add_option("-m", "--filematch", dest="filematch", default="./filematch.json",
			help="the directory to scan, default is filematch.json" )
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
	global fmtconfdir
	fmtconfdir = options.fmtconfdir
	global filematch
	filematch = options.filematch

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



def init_matchdict():
	global matchdict
	f = file(filematch)
	str1 = f.read().decode('utf-8-sig')

	matchdict = json.loads(str1)
	print "matchdict1", matchdict
	f.close()
	for k in matchdict.keys():
		matchdict[k] = re.compile(matchdict[k])

	# print "matchdict2", matchdict


def get_match_confile(filename):
	print filename
	for k in matchdict.keys():
		# print "k", k
		if matchdict[k].match(filename.decode('utf8')):
			return k
	return None


def find_gametype(gamename):
	cql = "SELECT gameid FROM gameranking_info WHERE gamename=?"
	cql_stmt = session.prepare(cql)
	logger.info( "cql:%s"%(cql) )
	rows = session.execute( cql_stmt, [gamename] )
	# print 'rows:',rows
	if len(rows) >0:
		return rows[0][0]
	return None

def find_gametype2(gamename):
	sql = "select id from hd_game where name='%s'"%(gamename)
	logger.debug( "sql:%s"%(sql) )
	rows = dbutil.select_sql(sql)
	if rows is None or len(rows)<=0:
		logger.error("no talbe to locate")
		return  0
	return rows[0][0]

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


def get_last_rankingpic(gameid, keys_dict):
	logger.info("================= clear last_rankingpic ==================")
	ranking = int(keys_dict['ranking'])
	if 'area' not in keys_dict.keys():
		keys_dict['area'] = g_area
	area = keys_dict['area']
	cql = "SELECT picurl FROM gameranking WHERE gameid=? and ranking=? and area=?"
	cql_stmt = session.prepare(cql)
	logger.info( "cql:%s"%(cql) )
	rows = session.execute( cql_stmt, [gameid, ranking, area] )
	if len(rows)<=0:
		return None
	pic_dict = json.loads(rows[0][0])
	return pic_dict



def handle_rankinglist( gameid, keys_dict, data, picurl):
	ranking = int(keys_dict['ranking'])
	if 'area' not in keys_dict.keys():
		keys_dict['area'] = g_area
	area = keys_dict['area']

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
	print 'select row:',rows
	if rows is None or len(rows)<=0:
		return False
	return True

def search_file(pattern, search_path=os.environ['PATH'], pathsep=os.pathsep):
	for path in search_path.split(os.pathsep):
		# print 'path:', path,os.path.join(path.decode('utf8'), pattern)
		# print  glob(r'./game/传奇霸业//10-*')
		# print  glob(os.path.join(path.decode('utf8'), pattern))
		for match in glob(os.path.join(path, pattern)):
			yield match

def get_rankingpic(ranking, search_path):
	# search_path = search_path.replace('[','\[')
	# search_path = search_path.replace(']','\]')
	pattern = ranking+"-*"
	print pattern,search_path
	matchs = list(search_file(pattern,search_path))
	print matchs
	return matchs


def main():
	global fmtconf,dfile, ofile,filematch,matchdict,f_client
	init()
	# init_fortest()
	init_matchdict()
	f_client = Fdfs_client('/etc/fdfs/client.conf')
	# p = re.compile("装备")
	# if p.match("装备.txt"):
	# 	print "hihiddddddddddddd"

	# bf = BlockFormatter(fmtconf)
	# bf.Formmating(dfile, ofile)
	logger.info( "begin......" )

	while 1:
		try:
			scan(scandir,scandir, fmtconfdir)
		except:
			logger.error('exception', exc_info = True)
		finally:
			time.sleep( sleep_time )

	logger.info( "end!!!!!!" )
	# scan("./", fmtconfdir)


if __name__ == "__main__":
	main()
