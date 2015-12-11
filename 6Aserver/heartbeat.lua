-- @Author: coldplay
-- @Date:   2015-11-21 16:18:47
-- @Last Modified by:   coldplay
-- @Last Modified time: 2015-12-11 16:36:49


local redis = require "resty.redis"
local str = require "resty.string"
local config = require "config"
local red_pool = require "redis_pool"

function beating(uid)
	-- if uid==nil then
	-- 	ngx.exit(ngx.HTTP_BAD_REQUEST)
	-- end
	local bupdate = false
	local diff_time = 0
	local req_time = os.time()
	-- local red = config.redis_connect()
	local ret,red = red_pool.get_connect()
	if ret == false then
		ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
	end
	local key = string.format("login:%s:last_logintime",uid)
	local res, errget= red:get(key)
	if not res then
		red_pool.close()
		-- red:set_keepalive(10000, 100)
	   ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
	end

	if res == ngx.null then
		bupdate = true
	else
		diff_time = os.difftime (req_time, res)
		-- if diff_time >= 60 then
			bupdate = true
		-- end
	end
	if bupdate==true then
		local alive_time = 300
		local now_min = tonumber(os.date("%M", os.time()))
		local now_hor = tonumber(os.date("%H", os.time()))
		-- local now_time = os.date("%H:%M", os.time())
		local online_key = "online:"..now_hor..":".. now_min

		-- local ok1, errset1 = red:sadd(online_key, uid)
		-- if not ok1 then
		-- 	ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
		-- end
		-- local ok1, errset1 = red:expire(online_key, 300)
		-- if not ok1 then
		-- 	ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
		-- end
		-- local ok, errset = red:setex(key, alive_time, req_time)
		-- if not ok then
		-- 	ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
		-- end

		local linetime_key = string.format("level:%s:linetime",uid)

		red:init_pipeline()
	    red:sadd(online_key, uid)
	    red:expire(online_key, 300)
	    red:setex(key, alive_time, req_time)
	    red:get(linetime_key)
	    local results, err = red:commit_pipeline()
	    if not results then
	        ngx.log(ngx.ERR,"failed to commit the pipelined requests: ", err)
	        return
	    end
	   local cjson = require "cjson"
	    -- ngx.say(cjson.encode(results))
	    -- ngx.log(ngx.ERR, #results)
	    for i, res1 in ipairs(results) do
           	if not res1 then
                ngx.log(ngx.ERR,"failed to run command ".. i.. ": ".. res1)
                return 400
            end
            if i == 4 then
            	linetime = res1
            end
        end
		-- local linetime, errget= red:get(linetime_key)
		-- ngx.log(ngx.ERR, "linetime1:",linetime )
		if  linetime == ngx.null then
			linetime = 0
			-- ngx.log(ngx.INFO, "linetime1:",linetime )
		end
		-- ngx.log(ngx.INFO, type(linetime) )
		-- ngx.log(ngx.INFO, linetime )
		nlinetime = tonumber(linetime) + 1
		-- local ok, errget= red:set(linetime_key, nlinetime)
		-- if not ok then
		--    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
		-- end

		local sql = "update chinau_member set line_time = line_time+1 where id=".. uid
		red:init_pipeline()
		red:set(linetime_key, nlinetime)
	    red:zrevrangebyscore("linetime", nlinetime, 0, "limit", 0 ,1)
	    red:lpush("chinau_6a",sql)
	    local results, err = red:commit_pipeline()
	    if not results then
	        ngx.log(ngx.ERR,"failed to commit the pipelined requests: ", err)
	        return 400
	    end

		-- ngx.say(cjson.encode(results))

	    for i, res2 in ipairs(results) do
            if type(res2) == "table" then
                if res2[1] ~= nil then
                	level_s = res2
                	-- ngx.log(ngx.ERR, "level:",level_s)
                    -- ngx.log(ngx.INFO,"failed to run command ".. i.. ": ".. res2[2])
                else

                     ngx.log(ngx.ERR,"failed to run command ".. i.. ": ".. res2[1])
                end
            else
            	if not res2 then
               		 ngx.log(ngx.ERR,"failed to run command ".. i.. ": ".. res2)
            	end
            end
        end
		local cjson = require "cjson"
		ngx.say(cjson.encode(level_s))
		-- 200 qps
		-- local res = ngx.location.capture("/task/level?userid="..uid.."&lt="..nlinetime)
		-- if res then
		-- 	if res.status == 200 then
  --               ngx.say(res.body)
  --           end
  --       end
		-- ngx.say(res)
		--不通过capture 性能 提升40-60qps luacache 没开情况下，开了性能同上面cpature相同
		-- local level_s = red:zrevrangebyscore("linetime", nlinetime, 0, "limit", 0 ,1)
		-- local cjson = require "cjson"
		-- ngx.say(cjson.encode(level_s))
		-- ngx.say(level_s)


		-- ngx.eof()
		-- local sql = "update chinau_member set line_time = line_time+1 where id=".. uid
		-- -- local cmd = "lpush chinau_6a".." \"".. sql.."\"\\r\\n"
		-- --1100qps
		-- local ans, err = red:lpush("chinau_6a",sql)
		--     if not ans then
		--     	ngx.log(ngx.ERR, err)
		--         ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
		--         return
		--     end
		red_pool.close()

		-- local ok, err = red:set_keepalive(10000, 100)
		--     if not ok then
		--     	ngx.log(ngx.ERR,"failed to set keepalive: ", err)
		--         return
		--     end
--capture
		    --local cmd = "lpush "..dbname.." \"".. data.."\"\\r\\n"
		    -- local res = ngx.location.capture(
		    --     "/mysql?dbname=chinau_6a"
		    --     ,{ method = ngx.HTTP_POST, body = sql }
		    -- )

		    -- local res = ngx.location.capture(
		    --     "/queue"
		   	--     )
--链接redis操作
		-- local sql = "update chinau_member set line_time = line_time+1 where id=".. uid
		-- local res = ngx.location.capture(
		--     "/mysql?dbname=chianu_6a"
		--     ,{ method = ngx.HTTP_POST, body = sql }
		-- )
		-- -- ngx.log(ngx.INFO,"hihi" )
		-- -- ngx.log(ngx.INFO,res.status )
		-- 	-- local res = ngx.location.capture("/mysql_chinau_6a?userid="..uid.."&lt="..nlinetime)
		-- if res then
		-- 	if res.status == 200 then
		-- 		-- ngx.log(ngx.ERR, res.body)
  --               -- ngx.say(res.body)
  --           end
  --       end
	end

--链接数据库操作
	-- 	local db = config.mysql_memeber_connect()
	-- 	if db == false then
	-- 		ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
	-- 		return
	-- 	end
	-- 	local sql = "update chinau_member set line_time = line_time+1 where id=".. uid
	-- 	ngx.log(ngx.INFO,sql)

	-- 	local res, err, errno, sqlstate = db:query(sql)
	-- 	if not res then
	-- 		ngx.log(ngx.ERR,"failed to query: ".. err .. ": ".. errno.. " ".. sqlstate)
	-- 		ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
	-- 		return
	-- 	end
	-- 	local ok, err = db:set_keepalive(10000, 100)
	-- 	if not ok then
	-- 	    ngx.log(ngx.ERR,"failed to set keepalive: ", err)
	-- 	    return
	-- 	end
	-- 	local ok, err = red:set_keepalive(10000, 100)
	-- 	if not ok then
	-- 	    ngx.log(ngx.ERR,"failed to set keepalive: ", err)
	-- 	    return
	-- 	end
	-- end

end


local args = ngx.req.get_uri_args(6)
local auid = ngx.quote_sql_str(args.userid)
beating(auid)
