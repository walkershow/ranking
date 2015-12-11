-- @Author: coldplay
-- @Date:   2015-12-09 14:17:57
-- @Last Modified by:   coldplay
-- @Last Modified time: 2015-12-11 16:58:12
ngx.req.read_body()  -- explicitly read the req body
local config = require "config"
local uri_args = ngx.req.get_uri_args(1)
local dbname = uri_args["dbname"]
local data = ngx.req.get_body_data()
-- ngx.log(ngx.INFO, "body:", data)
 ngx.var.sql = data
 if string.find(data, "select ") then
     return ngx.exec("@select_"..dbname)
 end
 if string.find(data, "update ") ~= nil or string.find(data, "insert ") ~= nil or string.find(data, "delete ") ~= nil then
     -- local res = ngx.location.capture("/mysql/queue_sql?dbname="..dbname,
     --     { method = ngx.HTTP_POST, body = data }
     -- )
    local ret,red = red_pool.get_connect()
    if ret == false then
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

     local ans, err = red:lpush(dbname,data)
         if not ans then
         	ngx.log(ngx.ERR, err)
         	red_pool.close()
            ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
         end

     red_pool.close()
     --性能与capture 无大差别（如果假如链接redis代码，性能下降10%）
     -- local cmd = "lpush "..dbname.." \"".. data.."\"\\r\\n"
     -- local res = ngx.location.capture(
     --     "/redis?dbname="..dbname
     --     ,{ method = ngx.HTTP_POST, body = cmd }
     -- )
     return 200
     -- return ngx.exec("@uid")
 end

return 400

