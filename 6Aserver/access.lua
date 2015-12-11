-- @Author: coldplay
-- @Date:   2015-11-10 17:04:53
-- @Last Modified by:   coldplay
-- @Last Modified time: 2015-12-11 16:10:06

-- local p = "/opt/openresty/work/conf/"
-- local m_package_path = package.path
-- package.path = string.format("%s;%s?.lua;",
--     m_package_path, p )


local tokentool = require "tokentool"
local config = require "config"
local args = ngx.req.get_uri_args(6)
local headers = ngx.req.get_headers()
-- ngx.log(ngx.INFO,"token:",tok)
-- ngx.log(ngx.INFO,"userid:",userid)
if args.tok == nil or args.userid == nil then
	ngx.log(ngx.ERR,"tok or userid is nil:")
    ngx.exit(ngx.HTTP_FORBIDDEN)
end


local userid =ngx.quote_sql_str(args.userid)
local tok =args.tok

-- ngx.log(ngx.ERR, "version:", config.version)
-- ngx.log(ngx.ERR,"header:",headers.ver)
-- ngx.log(ngx.ERR,"header:",headers.host)
 -- if headers.ver ~= config.version then
 -- 	ngx.log(ngx.ERR,"version:",  headers.ver)
 -- 	ngx.exit(ngx.HTTP_BAD_REQUEST)
 -- end

local ret = tokentool.has_token(userid, tok)
if  ret == false then
    ngx.exit(ngx.HTTP_FORBIDDEN)
end
-- ngx.log(ngx.ERR, "i'm done")
return
