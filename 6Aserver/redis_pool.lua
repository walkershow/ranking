-- @Author: coldplay
-- @Date:   2015-12-11 10:36:14
-- @Last Modified by:   coldplay
-- @Last Modified time: 2015-12-14 15:27:37

module("redis_pool", package.seeall)

local config = require"config"
local redis = require("resty.redis")

local redis_pool = {}

function redis_pool:get_connect()
    if ngx.ctx[redis_pool] then
       -- ngx.log(ngx.ERR,"yeah,pool has red ")
       return true, ngx.ctx[redis_pool]
    end

    local client, errmsg = redis:new()
    if not client then
        return false, "redis.socket_failed: " .. (errmsg or "nil")
    end

    client:set_timeout(1000)

    local result, errmsg = client:connect(config.redisconf.host, config.redisconf.port)
    if not result then
        return false, errmsg
    end
    local ok, err = client:select(1)
    if not ok then
    	ngx.log(ngx.ERR,"failed to select redis: "..err)
        return false
    end
    -- ngx.log(ngx.ERR,"client type: "..type(client))
    ngx.ctx[redis_pool] = client
    return true, ngx.ctx[redis_pool]
end

function redis_pool:close()
    if ngx.ctx[redis_pool] then
        ngx.ctx[redis_pool]:set_keepalive(10000, 300)
        ngx.ctx[redis_pool] = nil
    end
end



return redis_pool
