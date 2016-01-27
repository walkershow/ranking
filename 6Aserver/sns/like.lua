-- @Author: coldplay
-- @Date:   2015-11-27 16:37:53
-- @Last Modified by:   coldplay
-- @Last Modified time: 2016-01-12 11:49:16
ngx.req.read_body()
local headers = ngx.req.get_headers()
ngx.log(ngx.INFO,"referer:",ngx.var.http_referer)
ngx.log(ngx.INFO,headers["content_type"])
local uri_args = ngx.req.get_post_args(6)
local act = uri_args.act
local userid = uri_args["userid"]
local gameid = uri_args["gameid"]
local config = require "config"

local db = config.mysql_sns_connect()
if db == false then
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    return
end

if act == "add" then
    local sql = string.format("select 1 from ts_app_tag where row_id=%s and tag_id=%s",userid,gameid)
    ngx.log(ngx.INFO,sql)
    local  res, err, errno, sqlstate =  db:query(sql, 10)
    if not res then
        db:set_keepalive(10000, 100)
        ngx.log(ngx.ERR,"the sql:"..sql.." executed failed; bad result: ".. err.. ": ".. errno.. ": ".. sqlstate.. ".")
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
    if next(res) == nil then
         sql = string.format("insert into ts_app_tag(app,`table`,row_id,tag_id)"..
                            " values('public','user',%s,%s)",
                            userid,gameid)
    end
    ngx.log(ngx.INFO,sql)

    res, err, errno, sqlstate = db:query(sql)
    if not res then
        db:set_keepalive(10000, 100)
        ngx.log(ngx.ERR,"the sql:"..sql.." executed failed; bad result: ".. err.. ": ".. errno.. ": ".. sqlstate.. ".")
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        return
    end
elseif act == "del" then
    local sql = string.format("delete from ts_app_tag where row_id=%s and tag_id=%s",userid,gameid)
    ngx.log(ngx.INFO,sql)
    local res, err, errno, sqlstate = db:query(sql)
    if not res then
        db:set_keepalive(10000, 100)
        ngx.log(ngx.ERR,"the sql:"..sql.." executed failed; bad result: ".. err.. ": ".. errno.. ": ".. sqlstate.. ".")
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        return
    end
else
    ngx.log(ngx.ERR,"the act:"..act.." is not available")
    ngx.exit(ngx.HTTP_BAD_REQUEST)
end
local ok, err = db:set_keepalive(10000, 100)
if not ok then
    ngx.log(ngx.ERR,"failed to set keepalive: ", err)
    return
end


