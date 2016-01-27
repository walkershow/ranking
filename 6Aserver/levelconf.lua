-- @Author: coldplay
-- @Date:   2015-12-22 10:24:42
-- @Last Modified by:   coldplay
-- @Last Modified time: 2015-12-22 10:52:47

local level_config_cache = ngx.shared.level_config_cache
local level_conf = level_config_cache:get("level_config")
ngx.say(level_conf)
