local Interop = {}

Interop.m_Handlers = {}

Interop.m_ReturnCallbacks = {}

local type = type
local ipairs = ipairs
local xpcall = xpcall
local math_random = math.random
local table_concat = table.concat
local table_insert = table.insert
local util_TableToJSON = util.TableToJSON
local string_format = string.format

local characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
local charactersLength = #characters
local charArray = {}
for i = 1, charactersLength do
    charArray[i] = characters:sub(i, i)
end

local function randomString(length)
    local t = {}
    for i = 1, length do
        local index = math_random(1, charactersLength)
        t[i] = charArray[index]
    end
    return table_concat(t)
end

function Interop:RegisterHandler(handler)
    table.insert(self.m_Handlers, handler)
    table.sort(self.m_Handlers, function(a, b) return (a.Priority or 0) < (b.Priority or 0) end)
end

-- @include(promise.lua) --

-- Call when document ready.
function Interop:AttachToDHTML(dhtml)
    self:Reset()
    self.m_DHTML = dhtml
    dhtml:AddFunction("_interop_lua_", "call", function(id, callId, ...)
        local func = self:GetObject(id)
        if type(func) ~= "function" then
            error("Invalid function ID")
        end
        local parameters = {...}
        local p = {}
        for _,v in ipairs(parameters) do
            table_insert(p, self:FromJavascript(v))
        end
        local function cb(success, result)
            self:RunJavascriptFunction("_interop_js_.returnValue", callId, success, result)
        end
        local succ, ret = xpcall(func, function(err)
            cb(false, err)
        end, unpack(p))
        if succ then
            cb(true, ret)
        end
    end)
    dhtml:AddFunction("_interop_lua_", "returnValue", function(callId, success, value)
        local cb = self.m_ReturnCallbacks[callId]
        if cb then
            cb(success, self:FromJavascript(value))
            self.m_ReturnCallbacks[callId] = nil
        end
    end)
    dhtml:AddFunction("_interop_lua_", "collect", function(id)
        self:OnCollect(id)
    end)
end

function Interop:Reset()
    self.m_ReturnCallbacks = {}

    self.m_Objects = {}
    self.m_RefCount = {}
    self.m_Wrappers = {}
end

function Interop:UniqueID()
    return randomString(6)
end

function Interop:BuildJavascriptCallSignature(func, ...)
    local parameters = {...}
    local p = {}
    for _, v in ipairs(parameters) do
        table_insert(p, self:ToJavascript(v))
    end
    local json = util_TableToJSON(p)
    return string_format("%s(...%s)", func, json)
end

function Interop:RunJavascriptFunction(func, ...)
    if not self.m_DHTML then return end
    self.m_DHTML:RunJavascript(self:BuildJavascriptCallSignature(func, ...))
end

function Interop:AddFunction(path, callback)
    self:RunJavascriptFunction("_interop_js_.registerLuaFunction", path, callback)
end

function Interop:FromJavascript(obj, context)
    context = context or {}
    for _, handler in ipairs(self.m_Handlers) do
        local result = handler:From(obj, context)
        if result ~= nil then
            return result
        end
    end
    return nil
end

function Interop:ToJavascript(obj, context)
    context = context or {}
    for _, handler in ipairs(self.m_Handlers) do
        local result = handler:To(obj, context)
        if result ~= nil then
            return result
        end
    end
    return nil
end

-- @include(objects.lua) --

-- @HANDLER --

return Interop