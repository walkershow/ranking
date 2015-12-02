-- @Author: coldplay
-- @Date:   2015-11-21 16:18:47
-- @Last Modified by:   coldplay
-- @Last Modified time: 2015-11-27 16:09:51


local redis = require "resty.redis"
local aes = require "resty.aes"
local str = require "resty.string"
local config = require "config"

function beating(uid)
	if uid==nil then
		ngx.exit(ngx.HTTP_BAD_REQUEST)
	end
	local bupdate = false
	local diff_time = 0
	local req_time = os.time()
	local red = config.redis_connect()
	if red == false then
		ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
	end
	local key = string.format("login:%s:last_logintime",uid)
	local res, errget= red:get(key)
	if not res then
	   ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
	end

	if res == ngx.null then
		bupdate = true
	else
		diff_time = os.difftime (req_time, res)
		if diff_time >= 60 then
			bupdate = true
		end
	end
	if bupdate==true then
		local alive_time = 300
		local now_min = tonumber(os.date("%M", os.time()))
		local now_hor = tonumber(os.date("%H", os.time()))
		-- local now_time = os.date("%H:%M", os.time())
		local online_key = "online:"..now_hor..":".. now_min
		local ok1, errset1 = red:sadd(online_key, uid)
		if not ok1 then
			ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
		end
		local ok1, errset1 = red:expire(online_key, 300)
		if not ok1 then
			ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
		end
		local ok, errset = red:setex(key, alive_time, req_time)
		if not ok then
			ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
		end
		local db = config.mysql_memeber_connect()
		if db == false then
			ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
			return
		end

		local sql = "update chinau_member set line_time = line_time+1 where id=".. uid
		ngx.log(ngx.INFO,sql)

		local res, err, errno, sqlstate = db:query(sql)
		if not res then
			ngx.log(ngx.ERR,"failed to query: ".. err .. ": ".. errno.. " ".. sqlstate)
			ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
			return
		end
		local ok, err = db:set_keepalive(10000, 100)
		if not ok then
		    ngx.log(ngx.ERR,"failed to set keepalive: ", err)
		    return
		end
		local ok, err = red:set_keepalive(10000, 100)
		if not ok then
		    ngx.log(ngx.ERR,"failed to set keepalive: ", err)
		    return
		end
	end

end


local args = ngx.req.get_uri_args(6)
local auid = ngx.quote_sql_str(args.userid)
beating(auid)
