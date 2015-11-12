
local uri_args = ngx.req.get_uri_args()
local prog_md5 = uri_args["progmd5"]
local userid = uri_args["userid"]
local mysql = require "resty.mysql"
local config = require "config"

local db = config.mysql_gm_connect()
if db == false then
    ngx.log(ngx.ERR,"failed to instantiate mysql: ",err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    return
end

local sql
if prog_md5 == "all" then
    sql = "select progmd5,gameid from prog_to_game;"
else
    sql = "select b.id as gameid,name,iconurl,type, CAST(UNIX_TIMESTAMP() AS UNSIGNED) updatesign,progmd5,jburl,prog_title,prog_classname from prog_to_game a,hd_game b where a.progmd5=\'"..prog_md5.."\' and a.gameid=b.id"
end
local  res, err, errno, sqlstate =
        db:query(sql, 10)
if not res then
    ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
    return
end
if next(res) == nil then
    ngx.log(ngx.ERR,"res is null")
    return
end
-- for i, row in ipairs(res) do
--    for name, value in pairs(row) do
--      ngx.say("select row ", i, " : ", name, " = ", value, "<br/>")
--    end
-- end
local gameid = res[1]["gameid"]
local curtime = res[1]["updatesign"]
-- ngx.print(gameid,userid)

local sql_exist =string.format("select 1 from hd_user_gameinfo where userid=%s and gameid=%d", userid, gameid)
local res2, err2, errno2, sqlstate2 =
        db:query(sql_exist, 10)
-- for i, row in ipairs(res2) do
--    for name, value in pairs(row) do
--      ngx.say("select row ", i, " : ", name, " = ", value, "<br/>")
--    end
-- end
-- ngx.say(type(res))
if next(res2) == nil then
    sql = "insert into hd_user_gameinfo(userid,gameid,topmost,playtimes,lastplaytime,updatesign,status) values("..userid..","..gameid..",0,0,UNIX_TIMESTAMP(),"..curtime..",-1)"
    -- ngx.print(sql)
    res2, err2, errno2, sqlstate2 =
            db:query(sql, 10)
    if not res2 then
        ngx.say("bad result: ", err, ": ", errno2, ": ", sqlstate2, ".")
        return
    end
end

local cjson = require "cjson"
ngx.say(cjson.encode(res))

local ok, err = db:set_keepalive(10000, 100)
if not ok then
    ngx.log(ngx.ERR,"failed to set keepalive: ", err)
    return
end


