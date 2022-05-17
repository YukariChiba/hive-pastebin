local fs = require('fs')
local json = require('json')

local function uuid()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

local function decrease_meta_count(req)
    file_meta = fs.open(req.params.uuid .. ".meta")
    meta = json.parse(file_meta:read('a'))
    if meta.expire_counts > 0 then
        meta.expire_counts = meta.expire_counts - 1
    end
    local file_meta_write<close> = fs.open(req.params.uuid .. ".meta", "w")
    file_meta_write:write(json.stringify(meta))
    if meta.expire_counts == 0 then
        fs.remove(req.params.uuid .. ".txt")
        fs.remove(req.params.uuid .. ".meta")
    end
    return meta.expire_counts
end

local function get(req)
    if req.params.uuid then
        local file, err = fs.open(req.params.uuid .. ".txt")
        if not err then
            filedata = file:read('a')
            meta_readable, expire_counts = pcall(decrease_meta_count, req)
            if not meta_readable then expire_counts = -1 end
            return {content = filedata, expire_counts = expire_counts}
        else
            error({status = 404, error = err})
        end
    else
        error({status = 400, error = "No uuid"})
    end
end

local function post(req)
    local flag, bodyjson = pcall(req.body.parse_json, req.body)
    if flag then
        if bodyjson.content then
            local id = uuid()
            local file<close> = fs.open(id .. ".txt", "w")
            file:write(bodyjson.content)
            local expire_counts = math.tointeger(bodyjson.expire_counts)
            if not expire_counts then expire_counts = -1 end
            local file_meta<close> = fs.open(id .. ".meta", "w")
            file_meta:write(json.stringify({expire_counts = expire_counts}))
            return {uuid = id}
        else
            error({status = 400, error = "Blank content"})
        end
    else
        error({status = 400, error = "Blank content"})
    end
end

hive.register("/:uuid", routing.post(post):get(get))
hive.register("/", routing.post(post))
