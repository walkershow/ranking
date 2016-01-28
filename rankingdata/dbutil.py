#!/usr/bin/env python
#coding=gbk


import logging
import MySQLdb




###############################################################################################
logger = None

db_host = None
db_port = 3306
db_name = None
db_user = None
db_pwd = None
db_charset = "utf8"

db_conn = None
db_lasterrcode = 0


###############################################################################################
def from_dbstr(dbstring, mem_charset="gbk"):
	return dbstring.decode(db_charset).encode(mem_charset)

	
def to_dbstr(memstring, mem_charset="gbk"):
	return memstring.decode(mem_charset).encode(db_charset)


def error_duplicate_key():
	return db_lasterrcode == 1062


def create_connection():
	''' connect OK, return a connection handle; connect fail, return None'''

	global logger
	if logger is None:
		logger = get_default_logger()

	global db_conn
	if db_conn is None:
		try:
			db_conn = MySQLdb.connect(host=db_host, port=db_port, user=db_user, \
					passwd=db_pwd, db=db_name, charset=db_charset, use_unicode=False)
		except Exception, e:
			db_conn = None
			logger.error('exception', exc_info = True)
			if e.args is not None and len(e.args) > 0:
				global db_lasterrcode
				db_lasterrcode = e.args[0]
	return db_conn


def close_connection():
	global db_conn
	if db_conn is not None:
		try:
			db_conn.close()
		except Exception, e:
			logger.error('exception', exc_info = True)
		db_conn = None


def select_sql(sql): 
	''' result set: None--fail, empty[]--OK, no any data set, else[]--OK, has a data set '''

	logger.info(sql)
	if db_conn is None:
		create_connection()
	if db_conn is None:
		logger.error('db_conn is None')
		return None 

	try:
		cursor = db_conn.cursor()
		cursor.execute(sql)
		ret = cursor.fetchall()
		cursor.close()
		db_conn.commit()
		return ret
	except Exception, e:
		logger.error('exception', exc_info = True)
		if e.args is not None and len(e.args) > 0:
			global db_lasterrcode
			db_lasterrcode = e.args[0]
			if e.args[0] == 2003 or e.args[0] == 1152 or e.args[0] == 1042 or e.args[0] == 2006:
				close_connection()
		return None

def select_sqlwithdict(sql): 
	''' result set: None--fail, empty[]--OK, no any data set, else[]--OK, has a data set '''

	logger.info(sql)
	if db_conn is None:
		create_connection()
	if db_conn is None:
		logger.error('db_conn is None')
		return None 

	try:
		cursor = db_conn.cursor(MySQLdb.cursors.DictCursor)
		cursor.execute(sql)
		ret = cursor.fetchall()
		cursor.close()
		db_conn.commit()
		return ret
	except Exception, e:
		logger.error('exception', exc_info = True)
		if e.args is not None and len(e.args) > 0:
			global db_lasterrcode
			db_lasterrcode = e.args[0]
			if e.args[0] == 2003 or e.args[0] == 1152 or e.args[0] == 1042 or e.args[0] == 2006:
				close_connection()
		return None


def execute_sql(sql):
	''' -1--connect fail, -2--execute exception, 
		0--execute OK, but no effect, >0--execute OK, effect rows '''

	logger.info(sql)
	if db_conn is None:
		create_connection()
	if db_conn is None:
		logger.error('db_conn is None')
		return -1

	try:
		cursor = db_conn.cursor()
		ret = cursor.execute(sql)
		cursor.close()
		db_conn.commit()
		logger.info("ret=%d" % ret)
		return ret
	except Exception, e:
		logger.error('exception', exc_info = True)
		if e.args is not None and len(e.args) > 0:
			global db_lasterrcode
			db_lasterrcode = e.args[0]
			if e.args[0] == 2003 or e.args[0] == 1152 or e.args[0] == 1042 or e.args[0] == 2006:
				close_connection()
		return -2


###############################################################################################
class DBUtil:
	def __init__(self, log, dbhost, dbport, dbname, dbuser, dbpwd, charset):
		if log is None:
			self._logger = get_default_logger()
		else:
			self._logger = log

		self._host = dbhost
		self._port = dbport
		self._name = dbname
		self._user = dbuser
		self._pwd = dbpwd
		self._charset = charset

		self._conn = None
		self._lasterrcode = 0

	def create_connection(self):
		''' connect OK, return a connection handle; connect fail, return None'''

		if self._conn is None:
			try:
				self._conn = MySQLdb.connect(host=self._host, port=self._port, user=self._user,\
						passwd=self._pwd, db=self._name, charset=self._charset, \
						use_unicode=False)
			except Exception, e:
				self._conn = None
				self._logger.error('exception', exc_info = True)
				if e.args is not None and len(e.args) > 0:
					self._lasterrcode = e.args[0]
		return self._conn

	def close_connection(self):
		if self._conn is not None:
			try:
				self._conn.close()
			except Exception, e:
				self._logger.error('exception', exc_info = True)
			self._conn = None

	def select_sql(self, sql, cursorClass = 'Cursor'): 
		''' result set: None--fail, empty[]--OK, no any data set, else[]--OK, has a data set '''

		self._logger.info(sql)
		if self._conn is None:
			self.create_connection()
		if self._conn is None:
			self._logger.error('db_conn is None')
			return None 

		try:
			if cursorClass == 'DictCursor':
				cursor = self._conn.cursor(MySQLdb.cursors.DictCursor)
			else:
				cursor = self._conn.cursor()
			cursor.execute(sql)
			ret = cursor.fetchall()
			cursor.close()
			self._conn.commit()
			return ret
		except Exception, e:
			self._logger.error('exception', exc_info = True)
			if e.args is not None and len(e.args) > 0:
				self._lasterrcode = e.args[0]
				if e.args[0] == 2003 or e.args[0] == 1152 or e.args[0] == 1042 or e.args[0] == 2006:
					self.close_connection()
			return None

	def execute_sql(self, sql):
		''' -1--connect fail, -2--execute exception, 
			0--execute OK, but no effect, >0--execute OK, effect rows '''

		self._logger.info(sql)
		if self._conn is None:
			self.create_connection()
		if self._conn is None:
			self._logger.error('db_conn is None')
			return -1

		try:
			cursor = self._conn.cursor()
			ret = cursor.execute(sql)
			cursor.close()
			self._conn.commit()
			self._logger.info("ret=%d" % ret)
			return ret
		except Exception, e:
			self._logger.error('exception', exc_info = True)
			if e.args is not None and len(e.args) > 0:
				self._lasterrcode = e.args[0]
				if e.args[0] == 2003 or e.args[0] == 1152 or e.args[0] == 1042 or e.args[0] == 2006:
					self.close_connection()
			return -2


###############################################################################################
def get_default_logger():
	logger = logging.getLogger()
	logger.setLevel(logging.DEBUG)

	# console logger
	ch = logging.StreamHandler()
	ch.setLevel(logging.DEBUG)
	formatter = logging.Formatter("[%(asctime)s] [%(process)d] [%(module)s::%(funcName)s::%(lineno)d] [%(levelname)s]: %(message)s")
	ch.setFormatter(formatter)
	logger.addHandler(ch)
	return logger

if __name__ == '__main__':
	logger = get_default_logger()
	logger.debug("debug message")
	logger.info("info message")
	logger.warn("warn message")
	logger.error("error message")
	logger.critical("critical message")
