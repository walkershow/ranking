local uri_args = ngx.req.get_uri_args()
local userid = uri_args["userid"]
local curtime = uri_args["curtime"]
local mysql = require "resty.mysql"
local config = require "config"

local db = config.mysql_gm_connect()
if db == false then
    ngx.log(ngx.ERR,"failed to instantiate mysql: ",err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    return
end


-- local sql = string.format("select  a.gameid,name,iconurl,type,progmd5,updatesign,b.status from game_manage a,hd_user_gameinfo b,prog_to_game c where userid=%d and updatesign>%d and a.gameid=b.gameid and c.gameid=b.gameid",userid, curtime)
local sql = string.format("select  a.id as gameid,name,iconurl,type,updatesign,url,b.status,a.jburl,a.prog_title,a.prog_classname from hd_game a,hd_user_gameinfo b where userid=%d and updatesign>%d and a.id=b.gameid",userid, curtime)
ngx.log(ngx.ERR,sql)
local  res, err, errno, sqlstate =  db:query(sql, 10)
if not res then
    ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
    return
end
local cjson = require "cjson"
ngx.say(cjson.encode(res))

local ok, err = db:set_keepalive(10000, 100)
if not ok then
    ngx.say("failed to set keepalive: ", err)
    return
end

