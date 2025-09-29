local HANDLER = {}

HANDLER.Priority = 200

function HANDLER:From(obj)
    if Interop:ObjectType(obj) == "opaque" then
        local id = obj.id
        local object = Interop:GetObject(id)
        if object then
            -- Lua's opaque object, return it
            return object
        else
            -- Javascript's opaque object, notify JS if collected
            Interop:ListenForGC(obj, function()
                Interop:Collect(id)
            end)
            Interop.m_Wrappers[obj] = id
            return obj
        end
    end
end

function HANDLER:To(obj)
    if type(obj) == "table" and Interop:ObjectType(obj) == "opaque" then
        -- Javascript's opaque object, return it
        return obj
    end
    -- Lua's opaque object, create an interop object
    local id = Interop:UniqueID()
    Interop:RegisterObject(id, obj)
    return Interop:CreateObject("opaque", { id = id })
end