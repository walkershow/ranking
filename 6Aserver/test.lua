-- @Author: coldplay
-- @Date:   2015-12-05 14:34:14
-- @Last Modified by:   coldplay
-- @Last Modified time: 2015-12-09 15:48:31

ngx.req.read_body()
 local raw_data = ngx.req.get_body_data()
-- ngx.log(ngx.ERR, raw_data)
 local data = string.gsub(raw_data, "\\r\\n", "\n")
 local res = ngx.location.capture("/redis_post",
       { method = ngx.HTTP_PUT,
         body = data }
   )
 return res
--   ngx.print("[" .. res.body .. "]")
