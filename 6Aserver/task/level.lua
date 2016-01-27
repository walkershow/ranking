-- @Author: coldplay
-- @Date:   2015-12-02 16:30:13
-- @Last Modified by:   coldplay
-- @Last Modified time: 2015-12-24 10:39:07

local config = require "config"
local red_pool = require "redis_pool"
local uri_args = ngx.req.get_uri_args(6)
local id = ngx.quote_sql_str(uri_args["userid"])
local linetime = uri_args["lt"]
ngx.log(ngx.INFO, "linetime:",linetime)
-- local db = config.mysql_memeber_connect()
-- if db == false then
--     ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
--     return
-- end
-- local sql = "select level from chinau_member where id="..id
-- local res, err, errno, sqlstate = db:query(sql)
-- if not res then
--     ngx.log(ngx.ERR,"the sql:"..sql.." executed failed; bad result: ".. err.. ": ".. errno.. ": ".. sqlstate.. ".")
--     ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
--     return
-- end
local ret,red = red_pool.get_connect()
if ret == false then
	ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

if linetime == nil then
-- ngx.log(ngx.INFO, "hello")
	local linetime_key = string.format("level:%s:linetime",id)
	linetime, errget= red:get(linetime_key)
-- ngx.log(ngx.INFO, "linetime2:",linetime)
	if not linetime then
	   ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
	end
end

local level = red:zrevrangebyscore("chinau_level_config", linetime, 0, "limit", 0 ,1)

local cjson = require "cjson"
-- ngx.say(level[1])
-- ngx.say(type(level))
ngx.say(cjson.encode{level=(level[1] or ""),linetime=linetime})
ngx.eof()
red_pool.close()


