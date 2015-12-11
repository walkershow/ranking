-- @Author: coldplay
-- @Date:   2015-12-03 15:45:08
-- @Last Modified by:   coldplay
-- @Last Modified time: 2015-12-04 14:47:14


local p = "/opt/openresty/work/conf/?.lua;/opt/openresty/lualib/?.lua"
local m_package_path = package.path
package.path = string.format("%s;%s;",
    m_package_path, p )
local cp = "/opt/openresty/lualib/?.so;./?.so;/usr/local/lib/lua/5.1/?.so;/opt/openresty/luajit/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so"
local m_cpackage_path = package.cpath
print (m_cpackage_path)
package.cpath = string.format("%s;%s;", m_cpackage_path, cp )
print (package.path)
print (package.cpath)
local redis = require "resty.redis"
local str = require "string"
-- local config = require "config"

-- local querystring =  ngx.unescape_uri(ngx.var.query_string)
-- ngx.log(ngx.ERR, querystring)

local red = redis:new()
red:set_timeout(1000)
local ok, err = red:connect(r.host, r.port)
if not ok then
	-- ngx.log(ngx.ERR,"failed to connect redis: "..err)
	return false
end
ok, err = red:select(1)
if not ok then
	-- ngx.log(ngx.ERR,"failed to select redis: "..err)
    return false
end

local ans, err = red:brpop("chinau_6a",querystring)
    if not ans then
    	-- ngx.log(ngx.ERR, err)
        -- ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        return
    end

local ok, err = red:set_keepalive(10000, 100)
    if not ok then
    	-- ngx.log(ngx.ERR,"failed to set keepalive: ", err)
        return
    end
