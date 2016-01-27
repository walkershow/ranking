-- @Author: coldplay
-- @Date:   2015-11-21 16:18:47
-- @Last Modified by:   coldplay
-- @Last Modified time: 2015-12-17 17:14:32


-- local redis = require "resty.redis"
local str = require "resty.string"
local config = require "config"
local red_pool = require "redis_pool"
local conf_mem = ngx.shared.config

function beating(uid)
	-- if uid==nil then
	-- 	ngx.exit(ngx.HTTP_BAD_REQUEST)
	-- end
	local bupdate = false
	local diff_time = 0
	local interval_secs = tonumber(conf_mem:get('heartbeat_interval'))
	-- ngx.log(ngx.ERR, interval_secs)
	local interval_min = interval_secs/60
	-- os.time 和 os.date 会涉及系统调用，尽量使用 ngx_lua 提供的接口获取 Nginx 内部的缓存时间吧。系统调用的开销是很可观的。
	local req_time = ngx.time()

	local ret,red = red_pool.get_connect()
	if ret == false then
		ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
	end
	--最近一次心跳包接收时间
	local login_key = string.format("login:%s:last_beattime",uid)
	local res, errget= red:get(login_key)
	if not res then
		red_pool.close()
		-- red:set_keepalive(10000, 100)
	   ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)

	end

	if res == ngx.null then
		bupdate = true
		interval_min = 0
	else
		diff_time = os.difftime (req_time, res)
		-- if diff_time >= interval_secs then
			-- ngx.log(ngx.ERR,"should update linetime now")
			bupdate = true
		-- end
	end
	if bupdate==true then
		local beat_alive_time = interval_secs + 60 --最近一次心跳包记录存活时间
		local online_alive_time = interval_secs + 60 --在线记录存活时间
		local now_min = tonumber(os.date("%M", ngx.time()))
		local now_hor = tonumber(os.date("%H", ngx.time()))
		-- local now_time = os.date("%H:%M", os.time())
		local online_key = "online:"..now_hor..":".. now_min


		local linetime_key = string.format("level:%s:linetime",uid)

		local sql = string.format("update chinau_member set line_time = line_time+%d where id=%s", interval_min, uid)
		-- local nlinetime
		red:init_pipeline()
	    red:sadd(online_key, uid)
	    red:expire(online_key, online_alive_time)
	    red:setex(login_key, beat_alive_time, req_time)
	    -- red:get(linetime_key)
	    red:incrby(linetime_key, interval_min)

	    -- red:zrevrangebyscore("linetime", nlinetime, 0, "limit", 0 ,1)
	    red:lpush("chinau_6a",sql)
	    local results, err = red:commit_pipeline()
	    -- local cjson = require "cjson"
	    -- ngx.say(cjson.encode(results))
	    if not results then
	        ngx.log(ngx.ERR,"failed to commit the pipelined requests: ", err)
            red_pool.close()
            ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
	    end

	    for i, res in ipairs(results) do
            	if not res then
               		ngx.log(ngx.ERR,"failed to run command ".. i.. ": ".. (res or "nil"))
            		red_pool.close()
            		ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)

            	end
        end
        --客户端每次启动下载等级配置表，当触发升级条件后调用服务器level接口
  --       local level = red:zrevrangebyscore("linetime", nlinetime, 0, "limit", 0 ,1)
		-- local cjson = require "cjson"
		-- ngx.say(cjson.encode(level))
		red_pool.close()
	end
end


local args = ngx.req.get_uri_args(6)
local auid = ngx.quote_sql_str(args.userid)
beating(auid)
