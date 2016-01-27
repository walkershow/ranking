-- @Author: coldplay
-- @Date:   2016-01-06 17:12:35
-- @Last Modified by:   coldplay
-- @Last Modified time: 2016-01-09 09:30:15

local config = require "config"
local uri_args = ngx.req.get_uri_args(3)
local id = ngx.quote_sql_str(uri_args["userid"])
local add_score = uri_args["add_score"]
ngx.log(ngx.INFO, "updatescore")
if id == nil or add_score == nil then
	ngx.exit(ngx.HTTP_BAD_REQUEST)
end
local uw_cache = ngx.shared.user_wealth_cache
local cjson = require "cjson"
local score = uw_cache:get(id)
if score then
	ngx.log(ngx.INFO, "updatescore cache")
	uw_cache:incr(id, add_score)
else
	local db = config.mysql_memeber_connect()
	if db == false then
	    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
	end

	local sql = "select score from chinau_member_score where member_id="..id
	ngx.log(ngx.INFO, sql)
	local res, err, errno, sqlstate = db:query(sql)
	if not res then
	    ngx.log(ngx.ERR,"the sql:"..sql.." executed failed; bad result: ".. err .. ": ".. errno.. ": ".. sqlstate.. ".")
	    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
	    return
	end

	if res[1] == nil then
		db:set_keepalive(10000, 100)
		ngx.exit(ngx.HTTP_BAD_REQUEST)
	else
		score = res[1]["score"]
	end
	db:set_keepalive(10000, 100)
	ngx.log(ngx.INFO, "set updatescore cache")
	uw_cache:set( id, score )

end

return

