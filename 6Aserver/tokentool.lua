-- @Author: coldplay
-- @Date:   2015-11-09 16:02:45
-- @Last Modified by:   coldplay
-- @Last Modified time: 2015-12-11 11:28:54

module("tokentool", package.seeall)
local redis = require "resty.redis"
local aes = require "resty.aes"
local str = require "resty.string"
local config = require "config"
local red_pool = require "redis_pool"

local function connect()
    return config.redis_connect()
end

function add_token(uid, token)
    local red = connect()
    if red == false then
        return false
    end
    local key = string.format("login:%s:token",uid)
    local ok, err = red:setex(key, config.redisconf.alive_time, token)
    if not ok then
        red:set_keepalive(10000, 100)
        return false
    end
    red:set_keepalive(10000, 100)
    return true
end

function del_token(uid)
    local red = connect()
    if red == false then
        return
    end
    red:del(uid)
end

function has_token(uid, token)
    local ret,red = red_pool.get_connect()
    -- ngx.log(ngx.ERR,type(red))
    if ret == false then
        ngx.log(ngx.ERR,"connect redis failed.")
               return false
    end
    -- local red = connect()
    -- if red == false then
    --     ngx.log(ngx.ERR,"connect redis failed.")
    --     return false
    -- end
    ngx.log(ngx.INFO,uid)
    local key = string.format("login:%s:token",uid)
    local res, err = red:get(key)
    if not res then
        red_pool.close()
        return false
    end

    if res == ngx.null then
        ngx.log(ngx.ERR,"token not found.")
        red_pool.close()
        -- red:set_keepalive(10000, 100)
        return false
    end
    -- ngx.log(ngx.ERR,res)
    -- ngx.log(ngx.ERR,token)
    if res == token then
        -- red:set_keepalive(10000, 100)
        return res
    else
        ngx.log(ngx.ERR,"token is disable.")
        red_pool.close()
        -- red:set_keepalive(10000, 100)
        return false
    end
        -- red:set_keepalive(10000, 100)


end

-- generate token
function gen_token(uid)
    local rawtoken = uid .. " " .. ngx.now()
    local aes_128_cbc_md5 = aes:new(config.secrect_key)
    local encrypted = aes_128_cbc_md5:encrypt(rawtoken)
    local token = str.to_hex(encrypted)
    return token, rawtoken
end
