-- @Author: coldplay
-- @Date:   2015-12-03 15:22:11
-- @Last Modified by:   coldplay
-- @Last Modified time: 2015-12-10 17:20:37
local redis = require "resty.redis"
local str = require "resty.string"
local config = require "config"

-- ngx.log(ngx.ERR, package.cpath)
-- ngx.log(ngx.ERR, package.path)
local uri_args = ngx.req.get_uri_args(1)
local dbname = uri_args["dbname"]
ngx.req.read_body()  -- explicitly read the req body
local data = ngx.req.get_body_data()
--local querystring = ngx.unescape_uri(ngx.var.query_string)
-- ngx.log(ngx.ERR,"quque:", data)

    local cmd = "lpush "..dbname.." \"".. data.."\"\\r\\n"
    -- local res = ngx.location.capture(
    --     "/redis?dbname="..dbname
    --     ,{ method = ngx.HTTP_POST, body = cmd }
    -- )
    -- ngx.log(ngx.INFO,"hihi" )
    -- ngx.log(ngx.INFO,res.status )
    --     -- local res = ngx.location.capture("/mysql_chinau_6a?userid="..uid.."&lt="..nlinetime)
    --     if res then
    --         if res.status == 200 then
    --             -- ngx.log(ngx.ERR, res.body)
    --             -- ngx.say(res.body)
    --         end
    --     end
local red = config.redis_connect()
if red == false then
	ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

local ans, err = red:lpush(dbname,cmd)
    if not ans then
        red:set_keepalive(10000, 100)
    	ngx.log(ngx.ERR, err)
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        return
    end

local ok, err = red:set_keepalive(10000, 100)
    if not ok then
    	ngx.log(ngx.ERR,"failed to set keepalive: ", err)
        return
    end
