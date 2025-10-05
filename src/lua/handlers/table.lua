local HANDLER = {}

HANDLER.Priority = 100

function HANDLER:From(obj)
    if type(obj) == "table" then
        local t = Interop:ObjectType(obj)
        if t == "table" then
            -- Lua's table, return it as is
            return Interop:GetObject(obj.id)
        elseif not t then
            -- JavaScript plain table, convert its members
            local newTbl = {}
            for k, v in pairs(obj) do
                newTbl[k] = Interop:FromJavascript(v)
            end
            return newTbl
        end
    end
end

function HANDLER:To(obj)
    if type(obj) == "table" and not Interop:ObjectType(obj) then
        if table.IsSequential(obj) then
            -- Can't put metadata in sequential tables...
            local newTbl = {}
            for k, v in ipairs(obj) do
                newTbl[k] = Interop:ObjectType(v) and v or Interop:ToJavascript(v, context)
            end
            return newTbl
        else
            local objId = Interop:UniqueID()
            local newTbl = Interop:CreateObject("table", {
                _G_TableId = objId
            })
            local context = {
                parentTable = objId
            }
            for k, v in pairs(obj) do
                newTbl[k] = Interop:ObjectType(v) and v or Interop:ToJavascript(v, context)
            end
            if Interop:IsObjectReferenced(objId) then
                Interop:RegisterObject(objId, obj)
                Interop:RefObject(objId) -- Count the table usage itself, so it doesn't get collected while in use
            end
            return newTbl
        end
    end
end

Interop:RegisterHandler(HANDLER)