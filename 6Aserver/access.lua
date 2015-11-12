-- @Author: coldplay
-- @Date:   2015-11-10 17:04:53
-- @Last Modified by:   coldplay
-- @Last Modified time: 2015-11-12 17:47:46

-- local p = "/opt/openresty/work/conf/"
-- local m_package_path = package.path
-- package.path = string.format("%s;%s?.lua;",
--     m_package_path, p )

local curversion = "1.0"
local tokentool = require "tokentool"
local args = ngx.req.get_uri_args(10)
local headers = ngx.req.get_headers();
ngx.log(ngx.ERR,"header:",headers.ver)
ngx.log(ngx.ERR,"header:",headers.host)
 if headers.ver ~= "1.0" then
 	ngx.log(ngx.ERR,"version:",  headers.ver)
 	ngx.exit(ngx.HTTP_BAD_REQUEST)
 end
ngx.log(ngx.ERR,"token:",args.tok)
if args.tok == nil or args.userid == nil then
    ngx.exit(ngx.HTTP_FORBIDDEN)
end
local ret = tokentool.has_token(args.userid, args.tok)
if ret == ngx.null then
    ngx.exit(ngx.HTTP_FORBIDDEN)
elseif ret == false then
    ngx.exit(ngx.HTTP_FORBIDDEN)
end
return
