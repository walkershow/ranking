-- @Author: coldplay
-- @Date:   2015-12-24 10:23:31
-- @Last Modified by:   coldplay
-- @Last Modified time: 2015-12-24 10:30:31
ngx.req.read_body()
local uri_args = ngx.req.get_uri_args(1)
local userid = ngx.quote_sql_str(uri_args.userid)
local post_level = ngx.req.get_body_data()

local ret,red = red_pool.get_connect()
if ret == false then
	ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

if linetime == nil then
-- ngx.log(ngx.INFO, "hello")
	local linetime_key = string.format("level:%s:linetime",userid)
	linetime, errget= red:get(linetime_key)
-- ngx.log(ngx.INFO, "linetime2:",linetime)
	if not linetime then
	   ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
	end
end

local level = red:zrevrangebyscore("chinau_level_config", linetime, 0, "limit", 0 ,1)
local cjson = require "cjson"
if level == post_level then
	ngx.say(cjson.encode{result="accept"})
else
	ngx.say(cjson.encode{result="refuse"})
end
ngx.eof()
red_pool.close()
