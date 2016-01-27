-- @Author: coldplay
-- @Date:   2015-12-21 11:07:55
-- @Last Modified by:   coldplay
-- @Last Modified time: 2016-01-13 17:35:23
--curl -d "userid=100&gameids_cv=25&gameids_icon=25" http://192.168.1.181/gamepic
local config = require "config"
ngx.req.read_body()
args = ngx.req.get_post_args()
userid = ngx.quote_sql_str(args.userid)
cv_str = args.gameids_cv
icon_str = args.gameids_icon

ngx.log(ngx.ERR,userid..";"..(cv_str or "nil")..";".. (icon_str or "nil"))
if cv_str=="" and icon_str=="" then	ngx.exit(ngx.HTTP_OK) end
if cv_str==nil or icon_str==nil then	ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR) end
local cv_cache = ngx.shared.cv_cache
local icon_cache = ngx.shared.icon_cache

string.split = function(s, p)
    local rt= {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
    return rt
end

--未命中的封面
local left_cvid={}
--未命中的游戏图标
local left_iconid={}
--封面结果集
local cv_res = {}
--图标结果集
local icon_res = {}
cv_table =string.split(cv_str, ",")
for _,item in ipairs(cv_table) do
	local cv = cv_cache:get(item)
	if cv then
		-- ngx.log(ngx.ERR, cv)
		local row = {}
		row["id"] = item
		row["game_cv"] = cv
		table.insert(cv_res, row)
	else
		table.insert(left_cvid, item)
	end

end
	cv_str = table.concat(left_cvid,",")

icon_table=string.split(icon_str,",")
for _,item in ipairs(icon_table) do
	local icon = icon_cache:get(item)
	if icon then
		-- ngx.log(ngx.ERR, "icon:",icon)
		local row = {}
		row["id"] = item
		row["iconurl"] = icon
		table.insert(icon_res, row)
	else
		-- ngx.log(ngx.ERR, "item:",item)
		table.insert(left_iconid, item)
	end
end
icon_str = table.concat(left_iconid,",")
ngx.log(ngx.ERR, "icon_str:",icon_str)
local cjson = require "cjson"
local db = config.mysql_gm_connect()
if db == false then
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    return
end
local cv_sql
if cv_str ~=""  then cv_sql = "select concat(id, '') as id,video_img as game_cv from hd_game where id in("..cv_str..");" end

local icon_sql
if icon_str ~="" then  icon_sql = "select concat(id, '') asid,iconurl from hd_game where id in("..icon_str..");" end

sql = (cv_sql or "").. (icon_sql or "")
ngx.log(ngx.ERR, sql)
if sql == "" then
	ngx.say(cjson.encode{cv_res,icon_res})
	db:set_keepalive(10000, 200)
	return
end

local  res, err, errno, sqlstate =  db:query(sql)

if not res then
    db:set_keepalive(10000, 200)
    ngx.log(ngx.ERR,"bad result: ".. (err or "nil").. ": ".. (errno or "nil") .. ": ".. (sqlstate or "nil").. ".")
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end
for i, row in ipairs(res) do
	if cv_sql ~= nil then
		table.insert(cv_res, row)
		-- ngx.log(ngx.ERR, "set cache:","cv")
    	cv_cache:set(row["id"], row["game_cv"])
	else
		table.insert(icon_res, row)
		-- ngx.log(ngx.ERR, "set cache:","icon")
		icon_cache:set(row["id"], row["iconurl"])
	end
	-- cv_res[ row["id"] ] = row["game_cv"]
   	-- ngx.log(ngx.ERR, name, value)
end

local i = 2
while err == "again" do
    res, err, errno, sqlstate = db:read_result()
    if not res then
        ngx.log(ngx.ERR, "bad result #", i, ": ", err, ": ", errno, ": ", sqlstate, ".")
        -- return ngx.exit(500)
	else
	    for i, row in ipairs(res) do
	    	 table.insert(icon_res, row)
	    	 -- ngx.log(ngx.ERR, "set cache:","icon")
	         icon_cache:set(row["id"], row["iconurl"])
	    end
    	-- ngx.say(cjson.encode(icon_res))
    	i = i + 1
    end
end
ngx.say(cjson.encode{cv_res,icon_res})

-- ngx.log(ngx.ERR, cv_cache:get("15"), icon_cache:get("15"))
db:set_keepalive(10000, 200)
