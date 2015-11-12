-- @Author: coldplay
-- @Date:   2015-11-12 16:20:20
-- @Last Modified by:   coldplay
-- @Last Modified time: 2015-11-12 17:46:06
local uri_args = ngx.req.get_uri_args()
local id = uri_args["userid"]
local curtime = uri_args["curtime"]

local mysql = require "resty.mysql"
local config = require "config"

local db = config.mysql_memeber_connect()
if db == false then
    ngx.log(ngx.ERR,"failed to instantiate mysql: ",err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    return
end
local sql= string.format("select id,username,nick_name,sex, blood,image,image_history1,FROM_UNIXTIME(birthday,\'%%Y-%%c-%%e\') birthday,province_id, city_id,area_id,updatetime from chinau_member where id=%s and updatetime>%d",id,curtime)
ngx.log(ngx.ERR,sql)
res, err, errno, sqlstate = db:query(sql)
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
