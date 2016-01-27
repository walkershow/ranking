-- local headers = ngx.req.get_headers()
-- ngx.log(ngx.INFO,"referer:",ngx.var.http_referer)
-- ngx.log(ngx.INFO,headers["content_type"])
local uri_args = ngx.req.get_uri_args(6)
local prog_md5 = ngx.quote_sql_str(uri_args["progmd5"])
local userid = ngx.quote_sql_str(uri_args["userid"])
local config = require "config"

local db = config.mysql_gm_connect()
if db == false then
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    return
end

local sql
if prog_md5 == "all" then
    sql = "select progmd5,gameid from prog_to_game;"
else
    sql = "select b.id as gameid,name,iconurl,video_img,type, CAST(UNIX_TIMESTAMP() AS UNSIGNED) updatesign,progmd5,jburl,prog_title,"..
            "prog_classname from prog_to_game a,hd_game b where a.progmd5="..prog_md5.." and a.gameid=b.id"
end
local  res, err, errno, sqlstate = db:query(sql, 10)
if not res then
    ngx.log(ngx.ERR,"the sql:"..sql.." executed failed; bad result: ".. err.. ": ".. errno.. ": ".. sqlstate.. ".")
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    return
end
if next(res) == nil then
    db:set_keepalive(10000, 100)
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

-- local sql_exist =string.format("select 1 from hd_user_gameinfo where userid=%s and gameid=%d", userid, gameid)
-- ngx.log(ngx.INFO,sql_exist)
-- local res2, err2, errno2, sqlstate2 =
--         db:query(sql_exist, 10)
-- -- for i, row in ipairs(res2) do
-- --    for name, value in pairs(row) do
-- --      ngx.say("select row ", i, " : ", name, " = ", value, "<br/>")
-- --    end
-- -- end
-- -- ngx.say(type(res))
-- if next(res2) == nil then
--     sql = "insert into hd_user_gameinfo(userid,gameid,topmost,playtimes,lastplaytime,updatesign,status) values("..userid..","..gameid..",0,0,UNIX_TIMESTAMP(),"..curtime..",-1)"
--     ngx.log(ngx.INFO,sql)

--     -- ngx.print(sql)
--     res2, err2, errno2, sqlstate2 =
--             db:query(sql, 10)
--     if not res2 then
--         db:set_keepalive(10000, 100)
--        ngx.log(ngx.ERR,"the sql:"..sql.." executed failed; bad result: ".. err2.. ": ".. errno2.. ": ".. sqlstate2.. ".")
--        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
--         return
--     end
-- end

-- local url = string.format("/sns/like?userid=%s&gameid=%d",uri_args.userid, gameid)
-- ngx.log(ngx.ERR,url)
-- local res1 = ngx.location.capture(url)

putdata = string.format("act=add&userid=%s&gameid=%d&curtime=%s",uri_args["userid"], gameid, curtime)
local res1 = ngx.location.capture("/userfavor",{ method = ngx.HTTP_POST, body = putdata})
if res1 then
  ngx.log(ngx.INFO,"status: ", res1.status)
end


local putdata = string.format("act=del&userid=%s&gameid=%d",userid, gameid)
res1 = ngx.location.capture("/sns/like",{ method = ngx.HTTP_POST, body = putdata})
if res1 then
  ngx.log(ngx.INFO,"status: ", res1.status)
end

local cjson = require "cjson"
ngx.say(cjson.encode(res))

local ok, err = db:set_keepalive(10000, 100)
if not ok then
    ngx.log(ngx.ERR,"failed to set keepalive: ", err)
    return
end


