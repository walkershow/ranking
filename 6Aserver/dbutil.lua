-- @Author: coldplay
-- @Date:   2015-12-11 11:40:00
-- @Last Modified by:   coldplay
-- @Last Modified time: 2015-12-11 11:42:51
-- module("dbutil", package.seeall)
local mod_name = ...
local mysql_pool = require("mysql_pool")

function query(sql)

    local ret, res, _ = mysql_pool:query(sql)
    if not ret then
        ngx.log(ngx.ERR, "query db error. res: " .. (res or "nil"))
        return nil
    end

    return res
end

function execute(sql)

    local ret, res, sqlstate = mysql_pool:query(sql)
    if not ret then
        ngx.log(ngx.ERR, "mysql.execute_failed. res: " .. (res or 'nil') .. ",sql_state: " .. (sqlstate or 'nil'))
        return -1
    end

    return res.affected_rows
end
