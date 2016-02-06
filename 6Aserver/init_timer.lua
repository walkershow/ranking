-- @Author: coldplay
-- @Date:   2015-12-16 14:48:22
-- @Last Modified by:   coldplay
-- @Last Modified time: 2016-01-29 15:25:11
local config = require "config"

function init_timer(premature)
	local resty_lock = require "resty.lock"
	local lock = resty_lock:new("timer_locks")
	local elapsed, err = lock:lock("single_timer")
	    if not elapsed then
	        ngx.log(ngx.ERR,"failed to acquire the lock: ", err)
	        return
	    end
	local delay = config.timer_interval  -- in seconds
	local new_timer = ngx.timer.at
	local log = ngx.log
	local ERR = ngx.ERR
	local check
	check = function(premature)
	    -- log(ERR, "pid:"..ngx.worker.pid())
	    if not premature then
	       -- log(ERR, "pid:"..ngx.worker.pid()) -- do the health check other routine work
	       get_level_conf()
	       get_hb_interval()
	       get_upgrade_info()
	        local ok, err = new_timer(delay, check)
	        if not ok then
	            log(ERR, "failed to create timer: ", err)
	            return
	        end
	    end
	end
	local ok, err = new_timer(delay, check)
	if not ok then
	    log(ERR, "failed to create timer: ", err)
	end
end

function get_level_conf()
	local mysql = require "resty.mysql"
	local db = config.mysql_memeber_connect()
	if db == false then
	    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
	    return
	end
	local sql = "select `value` from chinau_config where ckey='level_conf_version'"
	local  res, err, errno, sqlstate = db:query(sql, 10)
	if not res then
	    ngx.log(ngx.ERR,"the sql:"..sql.." executed failed; bad result: ".. err.. ": ".. errno.. ": ".. sqlstate.. ".")
	    db:set_keepalive(10000, 100)
	    -- ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
	    return
	end
	-- for i, row in ipairs(res) do
	--    for name, value in pairs(row) do
	--      ngx.log(ngx.INFO,"select row "..i.. " : ".. name.. " = ".. value)
	--    end
	-- end
	local lvl_ver = res[1]["value"]
	-- ngx.log(ngx.INFO, lvl_ver)
	local conf_mem = ngx.shared.config
	local level_config_cache = ngx.shared.level_config_cache
	-- ngx.log(ngx.INFO, conf_mem:get('level_conf_version'))

	if conf_mem:get('level_conf_version') ~= lvl_ver then
		if lvl_ver == nil then
			return false
		end
		ngx.log(ngx.ERR, "level_config init...")
		conf_mem:set('level_conf_version', lvl_ver)
		sql = "select level,line_time from chinau_level_config order by line_time"
		local  res, err, errno, sqlstate = db:query(sql, 10)
		if not res then
		    ngx.log(ngx.ERR,"the sql:"..sql.." executed failed; bad result: ".. err.. ": ".. errno.. ": ".. sqlstate.. ".")
		    db:set_keepalive(10000, 100)
		    -- ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
		    return false
		end
		local cjson = require "cjson"
		local red_pool = require "redis_pool"
		local ret,red = red_pool.get_connect()
		if ret == false then
			ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
		end
		local res1, err = red:del("chinau_level_config")
		if not res1 then
		    red_pool.close()
		    db:set_keepalive(10000, 100)
		    return false
		end
		level_config_cache:delete("level_config")
		for i, row in ipairs(res) do
		   	ngx.log(ngx.INFO, row["line_time"], row["level"])
		   	level_config_cache:set("level_config", cjson.encode(res) )
			local res, err = red:zadd("chinau_level_config", row["line_time"], row["level"])
			if not res then
				ngx.log(ngx.ERR,err)
			    red_pool.close()
			    db:set_keepalive(10000, 100)
			    return false
			end
		end
	end
	db:set_keepalive(10000, 100)
	return true
end

function get_hb_interval()
	local mysql = require "resty.mysql"
	local db = config.mysql_memeber_connect()
	if db == false then
	    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
	    return
	end
	local sql = "select `value` from chinau_config where ckey='heartbeat_interval'"
	local  res, err, errno, sqlstate = db:query(sql, 10)
	if not res then
	    ngx.log(ngx.ERR,"the sql:"..sql.." executed failed; bad result: ".. err.. ": ".. errno.. ": ".. sqlstate.. ".")
	    db:set_keepalive(10000, 200)
	    return false
	end
	-- for i, row in ipairs(res) do
	--    for name, value in pairs(row) do
	--      ngx.log(ngx.ERR,"select row "..i.. " : ".. name.. " = ".. value)
	--    end
	-- end
	local interval = res[1]["value"]
	-- ngx.log(ngx.ERR, lvl_ver)
	local conf_mem = ngx.shared.config
	-- ngx.log( ngx.ERR, conf_mem:get('heartbeat_interval') )
	conf_mem:set("heartbeat_interval", interval)
	-- conf_mem['heartbeat_interval'] = interval
	-- ngx.log( ngx.ERR, "heartbeat_interval:",conf_mem:get('heartbeat_interval') )

	db:set_keepalive(10000, 200)
	return true
end

function get_upgrade_info()
	local mysql = require "resty.mysql"
	local db = config.mysql_memeber_connect()
	if db == false then
	    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
	    return
	end
	local sql = "select program_name,program_version,program_savepath,md5,url from chinau_program_info"
	local  res, err, errno, sqlstate = db:query(sql, 10)
	if not res then
	    ngx.log(ngx.ERR,"the sql:"..sql.." executed failed; bad result: ".. err.. ": ".. errno.. ": ".. sqlstate.. ".")
	    db:set_keepalive(10000, 200)
	    return false
	end
	local cjson = require "cjson"
	local upgrade_info_cache = ngx.shared.upgrade_info_cache
	upgrade_info_cache:set("upgrade_info", cjson.encode(res) )
	sql = "select max(program_version) version from chinau_program_info"
	res, err, errno, sqlstate = db:query(sql, 10)
	if not res then
	    ngx.log(ngx.ERR,"the sql:"..sql.." executed failed; bad result: ".. err.. ": ".. errno.. ": ".. sqlstate.. ".")
	    db:set_keepalive(10000, 200)
	    return false
	end
	local version_cache = ngx.shared.version_cache
	version_cache:set("version", res[1]["version"] )
	db:set_keepalive(10000, 200)
	-- ngx.log(ngx.INFO,version_cache:get("version") )
	-- ngx.log(ngx.INFO,upgrade_info_cache:get("upgrade_info") )
	return true
end

local new_timer = ngx.timer.at
local ok, err = new_timer(0, init_timer)
if not ok then
    log(ERR, "failed to create timer: ", err)
end
