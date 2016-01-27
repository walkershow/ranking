-- @Author: coldplay
-- @Date:   2015-12-22 16:45:52
-- @Last Modified by:   coldplay
-- @Last Modified time: 2016-01-11 14:58:52
local config = require "config"

local cv_cache = ngx.shared.cv_cache
local icon_cache = ngx.shared.icon_cache

local sql = "select video_img from hd_game where id="
local db = config.mysql_gm_connect()
if db == false then
    -- ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    return
end
local cv_keys = cv_cache:get_keys()
for _,item in ipairs(cv_keys) do
	local sql_query = sql .. item
	local  res, err, errno, sqlstate =  db:query(sql_query)

	if not res then
	    db:set_keepalive(10000, 200)
	    ngx.log(ngx.ERR,"bad result: ".. (err or "nil").. ": ".. (errno or "nil") .. ": ".. (sqlstate or "nil").. ".")
	    -- ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
	else
		local game_cv = res[1]["video_img"]
		cv_cache:set(item , game_cv)
	end
end

local sql = "select iconurl from hd_game where id="
local icon_keys = icon_cache:get_keys()
for _,item in ipairs(icon_keys) do
	local sql_query = sql .. item
	local  res, err, errno, sqlstate =  db:query(sql_query)

	if not res then
	    db:set_keepalive(10000, 200)
	    ngx.log(ngx.ERR,"bad result: ".. (err or "nil").. ": ".. (errno or "nil") .. ": ".. (sqlstate or "nil").. ".")
	    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
	else
		local game_cv = res[1]["iconurl"]
		icon_cache:set(item , game_cv)
	end
end
ngx.log(ngx.ERR, cv_cache:get("15"), icon_cache:get("15"))
