-- @Author: coldplay
-- @Date:   2015-11-27 11:28:51
-- @Last Modified by:   coldplay
-- @Last Modified time: 2015-12-15 14:51:43

local redis = require "resty.redis"
local aes = require "resty.aes"
local str = require "resty.string"
local config = require "config"
local red_pool = require "redis_pool"

function online()
	local keys = {}
	local now_min = tonumber(os.date("%M", os.time()))
	local now_hor = tonumber(os.date("%H", os.time()))
	ngx.log(ngx.INFO,now_min, type(now_min))

	local j = 0
	for i=now_min,now_min-5,-1	do
		keys[j] = "online:"..now_hor..":".. i
		j=j+1
	end
	local ret,red = red_pool.get_connect()
	if ret == false then
		ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
	end
	-- for k,v in ipairs(keys) do
	--     -- ngx.log(ngx.ERR,"get key:",v)
	-- end

	local res, errset1 = red:sunion(unpack(keys))
	if not res then
		ngx.log(ngx.ERR,"failed to query: ".. errset1 )
		red_pool.close()
	end
	-- local cjson = require "cjson"
	-- ngx.say(cjson.encode(res))
	-- keys = {}
	-- ngx.log(ngx.ERR,"key len3:", table.getn(keys))
	-- ngx.say(keys)
	-- ngx.log(ngx.ERR,type(res))
	-- local n = red:scard(res)
	local count = table.getn(res)
	-- ngx.log(ngx.ERR,"res len:", table.getn(res))
	local cjson = require "cjson"
	ngx.say(count)
	red_pool.close()
	return res
end

online()
