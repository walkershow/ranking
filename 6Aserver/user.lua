-- @Author: coldplay
-- @Date:   2015-11-10 15:51:38
-- @Last Modified by:   coldplay
-- @Last Modified time: 2015-11-20 15:02:32


local tokentool = require "tokentool"
local config = require "config"

local request_method = ngx.var.request_method
ngx.log(ngx.INFO,request_method)
-- ngx.say(request_method)
if "GET" == request_method then
    -- ngx.say("hihi")
    args = ngx.req.get_uri_args(6)
    -- ngx.say(args)
elseif "POST" == request_method then
    ngx.req.read_body()
    args = ngx.req.get_post_args()
    data = ngx.req.get_body_data()
    if data == nil then
        ngx.log(ngx.ERR, "get_body_data is nil.")
        ngx.exit(ngx.HTTP_FORBIDDEN)
    end
    ngx.log(ngx.INFO,data)
    ngx.log(ngx.INFO,data["nickname"])

    local db = config.mysql_memeber_connect()
    if db == false then
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        return
    end

    local cjson = require "cjson"
    local content = cjson.decode(data)
    local nickname = ngx.quote_sql_str(content["nickname"])
    local sex = ngx.quote_sql_str(content["sex"])
    local blood = ngx.quote_sql_str(content["bt"])
    local userid = ngx.quote_sql_str(content["acctid"])
    local year = content["year"]
    local mon = content["mon"]
    local day = content["day"]
    local imageid = ngx.quote_sql_str(content["imageid"])
    local imagehis = ngx.quote_sql_str(content["imagehis"])
    local provid = ngx.quote_sql_str(content["provid"])
    local cityid = ngx.quote_sql_str(content["cityid"])
    local areaid = ngx.quote_sql_str(content["areaid"])

    local sql
    local sql_exist =string.format("select 1 from chinau_member where id=%s", userid)
    local res2, err2, errno2, sqlstate2 =
            db:query(sql_exist, 10)
    if next(res2) == nil then
         sql = string.format("insert into chinau_member(id,nick_name,sex, blood,image,image_history1,birthday,province_id, city_id,area_id, updatetime)"..
                            "values(%s,%s,%s,%s,%s,%s,UNIX_TIMESTAMP(\'%d-%d-%d\'),%s,%s,%s,UNIX_TIMESTAMP())",
                            userid,nickname,sex,blood, imageid, imagehis,year,mon, day, provid,cityid,areaid)
    else
        if 0 == imageid then
             sql = string.format("update chinau_member set nick_name=%s, sex=%s, blood=%s,birthday=UNIX_TIMESTAMP(\'%d-%d-%d\'),province_id=%s,"..
                                "city_id=%s,area_id=%s,updatetime=UNIX_TIMESTAMP() where id=%s",
                                nickname,sex,blood, year,mon, day, provid, cityid, areaid, userid)

        else
             sql = string.format("update chinau_member set nick_name=%s, sex=%s, blood=%s,image=%s, image_history1=%s, birthday=UNIX_TIMESTAMP(\'%d-%d-%d\'),"..
                    "province_id=%s,city_id=%s,area_id=%s,updatetime=UNIX_TIMESTAMP() where id=%s",
                    nickname,sex,blood,imageid, imagehis, year,mon, day,  provid, cityid, areaid,userid)
        end
    end
    ngx.log(ngx.INFO,sql)
    res, err, errno, sqlstate = db:query(sql)
    if not res then
        ngx.log(ngx.ERR,"the sql:"..sql.." executed failed; bad result: ".. err.. ": ".. errno.. ": ".. sqlstate.. ".")
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        return
    end
    local ok, err = db:set_keepalive(10000, 100)
    if not ok then
        ngx.log(ngx.ERR,"failed to set keepalive: ", err)
        return
    end
    ngx.say("succ done")
end
