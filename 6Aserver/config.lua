-- @Author: coldplay
-- @Date:   2015-11-12 14:49:01
-- @Last Modified by:   coldplay
-- @Last Modified time: 2015-11-12 17:13:49

local mod_name = ...
local M = {}
local redis = require "resty.redis"
local aes = require "resty.aes"
local str = require "resty.string"
local mysql = require "resty.mysql"

local r = {}
-- toke有效期24小时
r['alive_time'] = 3600*24
r['host'] = "127.0.0.1"
r['port'] = 6379

local mysql_memeber = {}
mysql_memeber['host'] = "192.168.1.113"
mysql_memeber['port'] = 3306
mysql_memeber['database'] = "chinau_6a"
mysql_memeber['user'] = "dev"
mysql_memeber['password'] = "123"
mysql_memeber['max_packet_size'] = 1024 * 1024

local mysql_gm = {}
mysql_gm['host'] = "192.168.1.113"
mysql_gm['port'] = 3306
mysql_gm['database'] = "gm_data"
mysql_gm['user'] = "dev"
mysql_gm['password'] = "123"
mysql_gm['max_packet_size'] = 1024 * 1024

-- connect redis database
function M.redis_connect()
	local red = redis:new()
	red:set_timeout(1000)
	local ok, err = red:connect(r['host'], r['port'])
	if not ok then
		return false
	end
	ok, err = red:select(1)
	if not ok then
	    return false
	end
	return red
end

function M.mysql_gm_connect()
	local db, err = mysql:new()
	if not db then
	    return false
	end
	db:set_timeout(1000)

	local ok, err, errno, sqlstate = db:connect
	{
	    host = mysql_gm['host'],
	    port = mysql_gm['port'],
	    database = mysql_gm['database'],
	    user =  mysql_gm['user'],
	    password =  mysql_gm['password'],
	    max_package_size =  mysql_gm['max_package_size']
	 }

	if not ok then
	    return false
	end
	db:query("SET NAMES utf8;")
	return db
end

function M.mysql_memeber_connect()
	local db, err = mysql:new()
	if not db then
	    return false
	end
	db:set_timeout(1000)

	local ok, err, errno, sqlstate = db:connect
	{
	    host = mysql_memeber['host'],
	    port = mysql_memeber['port'],
	    database = mysql_memeber['database'],
	    user =  mysql_memeber['user'],
	    password =  mysql_memeber['password'],
	    max_package_size =  mysql_memeber['max_package_size']
	 }

	if not ok then
		ngx.log(ngx.ERR,"failed to connect: ", err, ": ", errno, " ", sqlstate)
	    return false
	end
	db:query("SET NAMES utf8;")

	return db
end
M['redis'] = r
M['mysql_memeber'] = mysql_memeber
M['mysql_gm'] = mysql_gm

return M
