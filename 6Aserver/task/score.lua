-- @Author: coldplay
-- @Date:   2015-12-02 16:30:08
-- @Last Modified by:   coldplay
-- @Last Modified time: 2015-12-02 16:40:24

local config = require "config"
local uri_args = ngx.req.get_uri_args(6)
local id = ngx.quote_sql_str(uri_args["userid"])

local db = config.mysql_memeber_connect()
if db == false then
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    return
end
local sql = "select score from chinau_member_score where member_id="..id
local res, err, errno, sqlstate = db:query(sql)
if not res then
    ngx.log(ngx.ERR,"the sql:"..sql.." executed failed; bad result: ".. err.. ": ".. errno.. ": ".. sqlstate.. ".")
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    return
end
local cjson = require "cjson"
ngx.say(cjson.encode(res))
ngx.eof()
local ok, err = db:set_keepalive(10000, 100)
if not ok then
    ngx.log(ngx.ERR,"failed to set keepalive: ", err)
    return
end

