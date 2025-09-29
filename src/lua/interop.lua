local Interop = {}

Interop.m_Handlers = {}

Interop.m_ReturnCallbacks = {}

local function randomString(length)
    local result = ""
    local characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local charactersLength = #characters
    for i = 1, length do
        local index = math.random(1, charactersLength)
        result = result .. characters:sub(index, index)
    end
    return result
end

function Interop:RegisterHandler(handler)
    table.insert(self.m_Handlers, handler)
    table.sort(self.m_Handlers, function(a, b) return (a.Priority or 0) < (b.Priority or 0) end)
end

-- @include(promise.lua) --

-- Call when document ready.
function Interop:AttachToDHTML(dhtml)
    self.m_DHTML = dhtml
    dhtml:AddFunction("_interop_lua_", "call", function(id, callId, ...)
        local func = self:GetObject(id)
        if type(func) ~= "function" then
            error("Invalid function ID")
        end
        local parameters = {...}
        local p = {}
        for _,v in ipairs(parameters) do
            table.insert(p, self:FromJavascript(v))
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

function Interop:UniqueID()
    return randomString(10)
end

function Interop:BuildJavascriptCallSignature(func, ...)
    local parameters = {...}
    local p = {}
    for _, v in ipairs(parameters) do
        table.insert(p, self:ToJavascript(v))
    end
    local json = util.TableToJSON(p)
    return string.format("%s(...%s)", func, json)
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