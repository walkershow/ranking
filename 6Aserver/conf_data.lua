-- @Author: coldplay
-- @Date:   2015-12-24 09:51:56
-- @Last Modified by:   coldplay
-- @Last Modified time: 2015-12-24 10:03:32
local conf_data = ngx.shared.config
local level_ver = conf_data:get("level_conf_version")
local hb_interval = conf_data:get("heartbeat_interval")
local cjson = require "cjson"
ngx.say(cjson.encode{level_ver=level_ver,hb_interval= hb_interval})
