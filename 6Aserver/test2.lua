-- @Author: coldplay
-- @Date:   2015-12-05 14:55:45
-- @Last Modified by:   coldplay
-- @Last Modified time: 2015-12-05 16:25:54

ngx.req.read_body()
 --local raw_data = ngx.req.get_body_data()
 local postargs = ngx.req.get_post_args(6)
 local n = postargs.n
 local reqs = postargs.cmds
 ngx.log(ngx.ERR,"num:", n)
 ngx.log(ngx.ERR,"reqs:", reqs)
 local reqss = string.gsub(reqs, "\\r\\n", "\r\n")
 local res = ngx.location.capture("/redis_multi_post?"..n,
       { method = ngx.HTTP_PUT,
         body = reqss }
   )
   ngx.print("[" .. res.body .. "]")
