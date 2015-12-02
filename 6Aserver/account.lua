-- @Author: coldplay
-- @Date:   2015-11-09 16:01:49
-- @Last Modified by:   coldplay
-- @Last Modified time: 2015-11-20 15:03:23
-- package.path = package.path .. ";".. ";/opt/openresty/work/conf/"

-- local p = "/opt/openresty/work/conf/"
-- local m_package_path = package.path
-- package.path = string.format("%s;%s?.lua;",
--     m_package_path, p )

-- rint(package.path)       --> lua文件的搜索路径

local tokentool = require "tokentool"
local config = require "config"
-- post only
local method = ngx.req.get_method()
if method ~= "POST" then
    ngx.exit(ngx.HTTP_FORBIDDEN)
    return
end
-- get args
local args = ngx.req.get_uri_args(6)
if args.act ~= "register" and args.act ~= "login" and args.act ~= "logout" and args.act ~= "updatepwd" then
    ngx.log(ngx.ERR,"the act:"..args.act.." is not available")
    ngx.exit(ngx.HTTP_BAD_REQUEST)
    return
end

local postargs = ngx.req.get_post_args(6)

-- connect to mysql;
local function connect()
    return config.mysql_memeber_connect()
end


function register(pargs)
    if pargs.username == nil then
        pargs.username = ""
    end
    if pargs.email == nil or pargs.password == nil then
        ngx.exit(ngx.HTTP_BAD_REQUEST)
        return
    end

    local db = connect()
    if db == false then
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        return
    end

    local res, err, errno, sqlstate = db:query("insert into account(username, password, email) "
                             .. "values (\'".. pargs.username .."\',\'".. pargs.password .."\',\'".. pargs.email .."\')")
    if not res then
        ngx.exit(ngx.HTTP_NOT_ALLOWED)
        return
    end

    local uid = res.insert_id
    local token, rawtoken = tokentool.gen_token(uid)

    local ret = tokentool.add_token(token, rawtoken)
    if ret == true then
        ngx.say(token)
    else
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
end

function login(pargs)
    if pargs.uid == nil or pargs.pwd == nil then
        ngx.log(ngx.ERR,"uid or pwd is nil.")
        ngx.exit(ngx.HTTP_BAD_REQUEST)
        return
    end
    local auid = ngx.quote_sql_str(pargs.uid)
    local apwd = ngx.quote_sql_str(pargs.pwd)
    ngx.log(ngx.INFO, "uid:", auid)
    ngx.log(ngx.INFO, "pwd:", apwd)
    local db = config.mysql_memeber_connect()
    if db == false then
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        return
    end

    local sql = "select id from chinau_member where id=".. auid .." and password=".. apwd .." limit 1"
	ngx.log(ngx.INFO,sql)

    local res, err, errno, sqlstate = db:query(sql)
    if not res then
        ngx.log(ngx.ERR,"failed to connect: ".. err .. ": ".. errno.. " ".. sqlstate)
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        return
    end

    --local cjson = require "cjson"
    --ngx.say(cjson.encode(res))
    if res[1] == nil then
        ngx.log(ngx.ERR,"the sql:("..sql..") query result is null")
        ngx.exit(ngx.HTTP_FORBIDDEN)
    end
    local uid = res[1].id
    local token, rawtoken = tokentool.gen_token(auid)
	ngx.log(ngx.INFO,"gen token:",token)

    local ret = tokentool.add_token(auid, token)
    if ret == true then
        ngx.say(token)
        local ok, err = db:set_keepalive(10000, 100)
        if not ok then
            ngx.log(ngx.ERR,"failed to set keepalive: ", err)
            return
        end
    else
        ngx.log(ngx.ERR,"add token failed")
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
end

function logout(pargs)
    if pargs.token == nil then
        ngx.exit(ngx.HTTP_BAD_REQUEST)
        return
    end

    tokentool.del_token(pargs.token)
    ngx.say("ok")
end

-- to be done
function updatepwd(pargs)
    local db = connect()
    if db == false then
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        return
    end
    ngx.say(pargs.username .. pargs.newpassword)
end

if args.act == "register" then
    register(postargs)
elseif args.act == "login" then
    login(postargs)
elseif args.act == "updatepwd" then
    updatepwd(postargs)
elseif args.act == "logout" then
    logout(postargs)
end

