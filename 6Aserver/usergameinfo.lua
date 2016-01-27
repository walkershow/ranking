-- @Author: coldplay
-- @Date:   2015-12-25 16:07:07
-- @Last Modified by:   coldplay
-- @Last Modified time: 2016-01-12 10:17:46

local uri_args = ngx.req.get_uri_args(6)
local userid = ngx.quote_sql_str(uri_args["userid"])
local curtime =  ngx.quote_sql_str(uri_args["curtime"])
local cv_curtime =  ngx.quote_sql_str(uri_args["cv_curtime"])
local config = require "config"

local userfavor_upsign_cache = ngx.shared.userfavor_upsign_cache
local gamedata_upsign_cache = ngx.shared.gamedata_upsign_cache

local sql_max_icon_upsign = string.format("select  max(updatesign) as max_updatesign from hd_user_gameinfo b where userid=%s ;",userid)
local sql_max_cv_upsign = string.format("select  max(a.time) as max_updatesign from  hd_game a,hd_user_gameinfo b where userid=%s ;",userid)
local db
function is_need_update(sql_max_upsign ,query_time, cache)
	local upsign = cache:get(userid)
	ngx.log(ngx.INFO,sql_max_upsign)
	ngx.log(ngx.INFO,"hit upsign cache:", upsign)
	ngx.log(ngx.INFO,"client query time:", query_time)
	query_time = tonumber(query_time)
	if not upsign then
		ngx.log(ngx.INFO,"no upsign cache hit")
		db = config.mysql_gm_connect()
		if db == false then
		    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
		    return false
		end
	    local  res, err, errno, sqlstate =  db:query(sql_max_upsign)

	    if not res then
	        db:set_keepalive(10000, 200)
	        ngx.log(ngx.ERR,"the sql:"..sql.." executed failed; bad result: ".. (err or "nil").. ": ".. (errno or "nil") .. ": ".. (sqlstate or "nil").. ".")
	        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
	        return
	    end
	    if res[1] == nil then return true end
	    upsign = res[1]["max_updatesign"]
	    cache:set(userid, upsign)
	end

	if upsign <= query_time then
	    return false
	end
	return true
end

if is_need_update(sql_max_icon_upsign, uri_args["curtime"], userfavor_upsign_cache ) == false and
   is_need_update(sql_max_cv_upsign, uri_args["cv_curtime"], gamedata_upsign_cache ) == false
then
	ngx.log(ngx.INFO, 'no need to update')
	ngx.exit(ngx.HTTP_OK)
end

if db== nil then
	db = config.mysql_gm_connect()
	if db == false then
	    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
	    return
	end
end

--用户喜爱游戏列表或者游戏本身更新都触发
local sql = string.format("select  a.id as gameid,name,iconurl,video_img as game_cv,type,updatesign,url,b.status,a.jburl,a.prog_title,a.prog_classname,time from hd_game a,hd_user_gameinfo b "..
                        "where userid=%s and (updatesign>%s or time>%s) and a.id=b.gameid ;",userid, curtime, cv_curtime)
ngx.log(ngx.INFO,sql)

local  res, err, errno, sqlstate =  db:query(sql)

if not res then
    db:set_keepalive(10000, 200)
    ngx.log(ngx.ERR,"the sql:"..sql.." executed failed; bad result: ".. (err or "nil").. ": ".. (errno or "nil") .. ": ".. (sqlstate or "nil").. ".")
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    return
end

local cjson = require "cjson"
ngx.say(cjson.encode(res))

local ok, err = db:set_keepalive(10000, 200)
if not ok then
    ngx.log(ngx.ERR,"failed to set keepalive: ", err)
    return
end

