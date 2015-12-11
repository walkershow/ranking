-- @Author: coldplay
-- @Date:   2015-12-11 17:32:19
-- @Last Modified by:   coldplay
-- @Last Modified time: 2015-12-11 17:39:04

local upload = require "resty.upload"
local cjson = require "cjson"

local chunk_size = 4096 -- should be set to 4096 or 8192

local filename
local file = nil

function get_filename(res)
    local filename = ngx.re.match(res,'(.+)filename="(.+)"(.*)')
    if filename then
        return filename[2]
    end
end

function existsFile(path)
    x = io.open(path)
    if x == nil then
        io.close()
        return false
    else
        x:close()
        return true
    end
end

local form, err = upload:new(chunk_size)
if not form then
    ngx.log(ngx.ERR, "failed to new upload: ", err)
    ngx.exit(500)
end

form:set_timeout(1000) -- 1 sec

local osfilepath = "/opt/openresty/nginx/proxy_temp/"
local i=0

while true do
    local typ, res, err = form:read()
    if not typ then
        ngx.say("failed to read: ", err)
        return
    end

    ngx.say("read: ", cjson.encode({typ, res}))

    if typ == "header" then
        if res[1] ~= "Content-Type" then
            filename = get_filename(res[2])
            if filename then
                i=i+1
                filepath = osfilepath  .. filename
                file = io.open(filepath,"w+")
                if not file then
                    ngx.say("failed to open file: ", filepath)
                    return
                end
            end
        end
    elseif typ == "body" then
        ngx.say("body begin")
        if file then
            file:write(res)
            ngx.say("write ok: ", res)
        end
    elseif typ == "part_end" then
        ngx.say("part_end")
        if file then
            file:close()
            file = nil
            ngx.say("file upload success")
        end
    elseif typ == "eof" then
        break
    end
end

local typ, res, err = form:read()
ngx.say("read: ", cjson.encode({typ, res}))

if i==0 then
    ngx.say("please upload at least one file!")
    return
end
