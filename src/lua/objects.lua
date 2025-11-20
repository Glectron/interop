Interop.m_Objects = {}
Interop.m_RefCount = {}
Interop.m_Wrappers = {}

local weak = {}
weak.__mode = "k"
setmetatable(Interop.m_Wrappers, weak)

function Interop:ObjectType(obj)
    if type(obj) ~= "table" then return nil end
    return obj._G_InteropType
end

function Interop:CreateObject(typ, obj)
    obj._G_InteropType = typ
    return obj
end

function Interop:RegisterObject(id, obj, data)
    self.m_Objects[id] = {
        object = obj,
        data = data
    }
end

function Interop:HasObject(id)
    return self.m_Objects[id] ~= nil
end

function Interop:GetObject(id)
    local obj = self.m_Objects[id]
    if obj then
        return obj.object
    end
    return nil
end

function Interop:GetObjectData(id)
    local obj = self.m_Objects[id]
    if obj then
        return obj.data
    end
    return nil
end

-- Collects a JavaScript object by its ID
function Interop:Collect(id)
    self:RunJavascriptFunction("_interop_js_.collect", id)
end

-- Collects a Lua object by its ID
function Interop:OnCollect(id)
    if self:UnrefObject(id) then
        local obj = self:GetObject(id)
        local objData = self:GetObjectData(id)
        for _, v in ipairs(self.m_Handlers) do
            if type(v.OnCollect) == "function" then
                v:OnCollect(id, obj, objData)
            end
        end
        obj = nil
        objData = nil
        self.m_Objects[id] = nil
        collectgarbage()
    end
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

function Interop:RefObject(id)
    local refCntTbl = self.m_RefCount
    refCntTbl[id] = (refCntTbl[id] or 0) + 1
end

-- Returns true if the object was unreferenced (ref count reached 0)
function Interop:UnrefObject(id)
    local refCntTbl = self.m_RefCount
    if refCntTbl[id] then
        refCntTbl[id] = refCntTbl - 1
        if refCntTbl[id] <= 0 then
            refCntTbl[id] = nil
            return true
        end
    elseif self.m_Objects[id] then
        -- Object exists but no ref count, just remove it
        return true
    end
    return false
end

function Interop:IsObjectReferenced(id)
    return self.m_RefCount[id] ~= nil
end
