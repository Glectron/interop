local Interop = {}

Interop.m_Handlers = {}

Interop.m_ReturnCallbacks = {}

-- @include(localize.lua) --

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
    table_insert(self.m_Handlers, handler)
    table_sort(self.m_Handlers, function(a, b) return (a.Priority or 0) < (b.Priority or 0) end)
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
        for _, v in ipairs(parameters) do
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
        local cbTbl = self.m_ReturnCallbacks
        local cb = cbTbl[callId]
        if cb then
            cb(success, self:FromJavascript(value))
            cbTbl[callId] = nil
        end
    end)
    dhtml:AddFunction("_interop_lua_", "collect", function(id)
        self:OnCollect(id)
    end)
end

function Interop:Reset()
    self.m_JavascriptQueue = nil

    self.m_ReturnCallbacks = {}

    self.m_Objects = {}
    self.m_RefCount = {}
    self.m_Wrappers = {}
end

function Interop:UniqueID()
    return randomString(6)
end

-- @include(javascript.lua) --

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
