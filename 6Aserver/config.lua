-- @Author: coldplay
-- @Date:   2015-11-12 14:49:01
-- @Last Modified by:   coldplay
-- @Last Modified time: 2016-01-08 11:35:53

local mod_name = ...
local M = {}
local redis = require "resty.redis"
local aes = require "resty.aes"
local str = require "resty.string"
local mysql = require "resty.mysql"

local secrect_key = "chinau_secrect_key"
local curversion = "1.0"
local r = {}
-- toke有效期24小时
local timer_interval = 5
r['alive_time'] = 3600*24
r['host'] = "192.168.1.181"
r['port'] = 6379

local mysql_memeber = {}
mysql_memeber['host'] = "192.168.1.183"
mysql_memeber['port'] = 3306
mysql_memeber['database'] = "chinau_6a"
mysql_memeber['user'] = "dev"
mysql_memeber['password'] = "123"
mysql_memeber['max_packet_size'] = 1024 * 1024

local mysql_gm = {}
mysql_gm['host'] = "192.168.1.183"
mysql_gm['port'] = 3306
mysql_gm['database'] = "gm_data"
mysql_gm['user'] = "dev"
mysql_gm['password'] = "123"
mysql_gm['max_packet_size'] = 1024 * 1024


local mysql_sns = {}
mysql_sns['host'] = "192.168.1.183"
mysql_sns['port'] = 3306
mysql_sns['database'] = "glthinksns"
mysql_sns['user'] = "dev"
mysql_sns['password'] = "123"
mysql_sns['max_packet_size'] = 1024 * 1024
-- connect redis database
function M.redis_connect()
	local red = redis:new()
	red:set_timeout(1000)
	local ok, err = red:connect(r.host, r.port)
	if not ok then
		ngx.log(ngx.ERR,"failed to connect redis: "..err)
		return false
	end
	ok, err = red:select(1)
	if not ok then
		ngx.log(ngx.ERR,"failed to select redis: "..err)
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
	    host = mysql_gm.host,
	    port = mysql_gm.port,
	    database = mysql_gm.database,
	    user =  mysql_gm.user,
	    password =  mysql_gm.password,
	    max_package_size =  mysql_gm.max_package_size
	 }
	 -- local times, err = db:get_reused_times()
	 -- 	ngx.log(ngx.ERR, times)
	if not ok then
	    ngx.log(ngx.ERR,"failed to connect: "..(err or "nil")..": ".. (errno or 'nil'))
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
	db:set_timeout(5000)

	local ok, err, errno, sqlstate = db:connect
	{
	    host = mysql_memeber.host,
	    port = mysql_memeber.port,
	    database = mysql_memeber.database,
	    user =  mysql_memeber.user,
	    password =  mysql_memeber.password,
	    max_package_size =  mysql_memeber.max_package_size
	}
	-- local times, err = db:get_reused_times()
	--  	ngx.log(ngx.ERR, "dbtime:",times)
	if not ok then
		--errno 会有nil的情况？
		ngx.log(ngx.ERR,"failed to connect: "..(err or "nil")..": ".. (errno or 'nil'))
	    return false
	end
	db:query("SET NAMES utf8;")

	return db
end

function M.mysql_sns_connect()
	local db, err = mysql:new()
	if not db then
	    return false
	end
	db:set_timeout(1000)

	local ok, err, errno, sqlstate = db:connect
	{
	    host = mysql_sns.host,
	    port = mysql_sns.port,
	    database = mysql_sns.database,
	    user =  mysql_sns.user,
	    password =  mysql_sns.password,
	    max_package_size =  mysql_sns.max_package_size
	}
	-- local times, err = db:get_reused_times()
	--  	ngx.log(ngx.ERR, times)
	if not ok then
		ngx.log(ngx.ERR,"failed to connect: "..(err or "nil")..": ".. (errno or 'nil'))
	    return false
	end
	db:query("SET NAMES utf8;")

	return db
end

M['redisconf'] = r
M['mysql_memeber'] = mysql_memeber
M['mysql_gm'] = mysql_gm
M['mysql_sns'] = mysql_sns
M['version'] = curversion
M['secrect_key'] = secrect_key
M['timer_interval'] = timer_interval


return M
