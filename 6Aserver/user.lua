-- @Author: coldplay
-- @Date:   2015-11-10 15:51:38
-- @Last Modified by:   coldplay
-- @Last Modified time: 2015-11-12 17:49:13


local tokentool = require "tokentool"
local config = require "config"

local request_method = ngx.var.request_method
ngx.log(ngx.ERR,request_method)
-- ngx.say(request_method)
if "GET" == request_method then
    -- ngx.say("hihi")
    args = ngx.req.get_uri_args(10)
    -- ngx.say(args)
elseif "POST" == request_method then
    ngx.log(ngx.ERR,"ok?")
    ngx.req.read_body()
    args = ngx.req.get_post_args()
    data = ngx.req.get_body_data()
    if data == nil then
        ngx.log(ngx.ERR, "no data read")
    end
    ngx.log(ngx.ERR,ngx.req.get_body_data())
    ngx.log(ngx.ERR,data["nickname"])

    local db = config.mysql_memeber_connect()
    if db == false then
        ngx.log(ngx.ERR,"failed to instantiate mysql: ",err)
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        return
    end

    local cjson = require "cjson"
    local content = cjson.decode(data)
    local nickname = content["nickname"]
    local sex = content["sex"]
    local blood = content["bt"]
    local userid = content["acctid"]
    local year = content["year"]
    local mon = content["mon"]
    local day = content["day"]
    local imageid = content["imageid"]
    local imagehis = content["imagehis"]
    local provid = content["provid"]
    local cityid = content["cityid"]
    local areaid = content["areaid"]

    local sql
    local sql_exist =string.format("select 1 from chinau_member where id=%d", userid)
    local res2, err2, errno2, sqlstate2 =
            db:query(sql_exist, 10)
    if next(res2) == nil then
         sql = string.format("insert into chinau_member(id,nick_name,sex, blood,image,image_history1,birthday,province_id, city_id,area_id, updatetime) values(%d,\'%s\',%d,\'%s\',%d,\'%s\',UNIX_TIMESTAMP(\'%d-%d-%d\'),%d,%d,%d,UNIX_TIMESTAMP())",userid,nickname,sex,blood, imageid, imagehis,year,mon, day, provid,cityid,areaid)
    else
        if 0 == imageid then
             sql = string.format("update chinau_member set nick_name=\'%s\', sex=%d, blood=\'%s\',birthday=UNIX_TIMESTAMP(\'%d-%d-%d\'),province_id=%d,city_id=%d,area_id=%d,updatetime=UNIX_TIMESTAMP() where id=%d",nickname,sex,blood, year,mon, day, provid, cityid, areaid, userid)

        else
             sql = string.format("update chinau_member set nick_name=\'%s\', sex=%d, blood=\'%s\',image=%d, image_history1=\'%s\', birthday=UNIX_TIMESTAMP(\'%d-%d-%d\'),province_id=%d,city_id=%d,area_id=%d,updatetime=UNIX_TIMESTAMP() where id=%d",nickname,sex,blood,imageid, imagehis, year,mon, day,  provid, cityid, areaid,userid)
        end
    end
    ngx.log(ngx.ERR,sql)
    res, err, errno, sqlstate = db:query(sql)
    if not res then
        ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
        return
    end
    local ok, err = db:set_keepalive(10000, 100)
    if not ok then
        ngx.say("failed to set keepalive: ", err)
        return
    end
    ngx.say("succ done")
end
