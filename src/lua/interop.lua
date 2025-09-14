local Interop = {}

Interop.m_Handlers = {}

Interop.m_Objects = {}
Interop.m_Wrappers = {}

local weak = {}
weak.__mode = "k"
setmetatable(Interop.m_Wrappers, weak)

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

function Interop:CreatePromise()
    local resolved = false
    local rejected = false
    local value = nil
    local err = nil
    local promise = {}
    function promise:Then(onResolve)
        if resolved then
            if onResolve then onResolve(value) end
        else
            self._onResolve = onResolve
        end
        return self
    end
    function promise:Catch(onReject)
        if rejected then
            if onReject then onReject(err) end
        else
            self._onReject = onReject
        end
        return self
    end
    function promise:Final(onFinal)
        if resolved or rejected then
            if onFinal then onFinal() end
        else
            self._onFinal = onFinal
        end
        return self
    end
    function resolve(val)
        if not resolved and not rejected then
            resolved = true
            value = val
            if promise._onResolve then
                promise._onResolve(value)
            end
            if promise._onFinal then
                promise._onFinal()
            end
        end
    end
    function reject(e)
        if not resolved and not rejected then
            rejected = true
            err = e
            if promise._onReject then
                promise._onReject(err)
            end
            if promise._onFinal then
                promise._onFinal()
            end
        end
    end
    return promise, resolve, reject
end

-- Call when document ready.
function Interop:AttachToDHTML(dhtml)
    self.m_DHTML = dhtml
    dhtml:AddFunction("_interop_lua_", "call", function(id, callId, ...)
        local func = self.m_Objects[id]
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
        self.m_Objects[id] = nil
        collectgarbage()
    end)
end

function Interop:UniqueID()
    return randomString(10)
end

function Interop:BuildJavascriptCallSignature(func, ...)
    local parameters = {...}
    local p = {}
    for _,v in ipairs(parameters) do
        table.insert(p, self:ToJavascript(v))
    end
    local json = util.TableToJSON(p)
    return string.format("%s(%s)", func, json)
end

function Interop:RunJavascriptFunction(func, ...)
    if not self.m_DHTML then return end
    self.m_DHTML:RunJavascript(self:BuildJavascriptCallSignature(func, ...))
end

function Interop:AddFunction(path, callback)
    self:RunJavascriptFunction("_interop_js_.registerLuaFunction", path, callback)
end

function Interop:Collect(id)
    self:RunJavascriptFunction("_interop_js_.collect", id)
end

function Interop:CreateJavascriptObject(type, obj)
    obj._G_InteropType = type
    return obj
end

function Interop:ObjectType(obj)
    if type(obj) ~= "table" then return nil end
    return obj._G_InteropType
end

function Interop:FromJavascript(obj)
    for _, handler in ipairs(self.m_Handlers) do
        local result = handler:From(obj)
        if result ~= nil then
            return result
        end
    end
    return nil
end

function Interop:ToJavascript(obj)
    for _, handler in ipairs(self.m_Handlers) do
        local result = handler:To(obj)
        if result ~= nil then
            return result
        end
    end
    return nil
end

function Interop:ListenForGC(obj, callback)
    local p = newproxy(true)
    local pmeta = getmetatable(p)
    function pmeta:__gc()
        callback()
    end
    local meta = getmetatable(obj) or {}
    meta["_g_gc_proxy"] = p
    setmetatable(obj, meta)
end

-- @HANDLER --

return Interop