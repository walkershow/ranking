-- @Author: coldplay
-- @Date:   2015-12-25 17:16:21
-- @Last Modified by:   coldplay
-- @Last Modified time: 2016-01-12 15:13:45

ngx.req.read_body()
args = ngx.req.get_post_args()

local act = args.act
local userid =  ngx.quote_sql_str(args.userid)
local gameid =  ngx.quote_sql_str(args.gameid)
--progtogame 是传进来
local curtime =  args.curtime
if not curtime then
  curtime = ngx.time()
end
local config = require "config"
-- ngx.print(gameid,userid)
local db = config.mysql_gm_connect()
if db == false then
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    return
end

local sql_exist =string.format("select 1 from hd_user_gameinfo where userid=%s and gameid=%s", userid, gameid)
ngx.log(ngx.INFO,sql_exist)
local res2, err2, errno2, sqlstate2 =
        db:query(sql_exist, 10)
if not res2 then
   db:set_keepalive(10000, 100)
   ngx.log(ngx.ERR,"the sql:"..sql_exist.." executed failed; bad result: ".. err2.. ": ".. errno2.. ": ".. sqlstate2.. ".")
   ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    return
end

local userfavor_upsign_cache = ngx.shared.userfavor_upsign_cache


-- for i, row in ipairs(res2) do
--    for name, value in pairs(row) do
--      ngx.say("select row ", i, " : ", name, " = ", value, "<br/>")
--    end
-- end
-- ngx.say(type(res))

local sql
if act=='add' then
  if next(res2) == nil then
    sql = "insert into hd_user_gameinfo(userid,gameid,topmost,playtimes,lastplaytime,updatesign,status) values("..userid..","..gameid..",0,0,UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),-1)"
  else
    sql = string.format("update hd_user_gameinfo set status=-1,updatesign=UNIX_TIMESTAMP() where userid=%s and gameid=%s", userid, gameid )
  end
elseif act =='del' then
	sql = string.format('update hd_user_gameinfo set status=0,updatesign=UNIX_TIMESTAMP() where userid=%s and gameid=%s', userid, gameid )
else
	ngx.exit(ngx.HTTP_BAD_REQUEST)
end

ngx.log(ngx.INFO,sql)
res2, err2, errno2, sqlstate2 = db:query(sql)
if not res2 then
   db:set_keepalive(10000, 100)
   ngx.log(ngx.ERR,"the sql:"..sql.." executed failed; bad result: ".. err2.. ": ".. errno2.. ": ".. sqlstate2.. ".")
   ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
   return
end

sql = string.format("select updatesign from hd_user_gameinfo where userid=%s and gameid=%s", userid, gameid )
res2, err2, errno2, sqlstate2 = db:query(sql)
if not res2 then
   db:set_keepalive(10000, 100)
   ngx.log(ngx.ERR,"the sql:"..sql.." executed failed; bad result: ".. err2.. ": ".. errno2.. ": ".. sqlstate2.. ".")
   ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
   return
end
userfavor_upsign_cache:set(userid, res2[1][updatesign])
-- local url = string.format("/sns/like?userid=%s&gameid=%d",uri_args.userid, gameid)
-- ngx.log(ngx.ERR,url)
-- local res1 = ngx.location.capture(url)
--给说说使用
local putdata = string.format("act=add&userid=%s&gameid=%s",userid, gameid)
local res1 = ngx.location.capture("/sns/like",{ method = ngx.HTTP_POST, body = putdata})
if res1 then
  ngx.log(ngx.INFO,"status: ", res1.status)
end

local ok, err = db:set_keepalive(10000, 100)
if not ok then
    ngx.log(ngx.ERR,"failed to set keepalive: ", err)
    return
end
