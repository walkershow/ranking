local uri_args = ngx.req.get_uri_args(6)
local userid = ngx.quote_sql_str(uri_args["userid"])
local curtime = ngx.quote_sql_str(uri_args["curtime"])
local config = require "config"

local db = config.mysql_gm_connect()
if db == false then
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    return
end


-- local sql = string.format("select  a.gameid,name,iconurl,type,progmd5,updatesign,b.status from game_manage a,hd_user_gameinfo b,prog_to_game c where userid=%d and updatesign>%d and a.gameid=b.gameid and c.gameid=b.gameid",userid, curtime)
local sql = string.format("select  a.id as gameid,name,iconurl,type,updatesign,url,b.status,a.jburl,a.prog_title,a.prog_classname from hd_game a,hd_user_gameinfo b "..
						"where userid=%s and updatesign>%s and a.id=b.gameid",userid, curtime)
ngx.log(ngx.INFO,sql)
local  res, err, errno, sqlstate =  db:query(sql, 10)
if not res then
    ngx.log(ngx.ERR,"the sql:"..sql.." executed failed; bad result: ".. err.. ": ".. errno.. ": ".. sqlstate.. ".")
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    return
end
local cjson = require "cjson"
ngx.say(cjson.encode(res))

local ok, err = db:set_keepalive(10000, 100)
if not ok then
    ngx.log(ngx.ERR,"failed to set keepalive: ", err)
    return
end

