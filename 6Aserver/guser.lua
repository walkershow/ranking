-- @Author: coldplay
-- @Date:   2015-11-12 16:20:20
-- @Last Modified by:   coldplay
-- @Last Modified time: 2015-11-20 15:02:19
local uri_args = ngx.req.get_uri_args(6)
local id = ngx.quote_sql_str(uri_args["userid"])
local curtime = ngx.quote_sql_str(uri_args["curtime"])

local config = require "config"

local db = config.mysql_memeber_connect()
if db == false then
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    return
end
local sql= string.format("select id,username,nick_name,sex, blood,image,image_history1,FROM_UNIXTIME(birthday,\'%%Y-%%c-%%e\') birthday,province_id,"..
							"city_id,area_id,updatetime from chinau_member where id=%s and updatetime>%s",id,curtime)
ngx.log(ngx.INFO,sql)
res, err, errno, sqlstate = db:query(sql)
if not res then
    ngx.log(ngx.ERR, "bad result: ".. err.. ": ".. errno.. ": ".. sqlstate.. ".")
    return
end
local cjson = require "cjson"
ngx.say(cjson.encode(res))

local ok, err = db:set_keepalive(10000, 100)
if not ok then
    ngx.log(ngx.ERR,"failed to set keepalive: ", err)
    return
end
