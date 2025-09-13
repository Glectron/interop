local HANDLER = {}

HANDLER.Priority = 10

function HANDLER:From(obj)
    -- Convert from primitive types to themselves
    local t = type(obj)
    if t == "nil" or t == "boolean" or t == "number" or t == "string" then
        return obj
    end
end

function HANDLER:To(obj)
    -- Convert from primitive types to themselves
    local t = type(obj)
    if t == "nil" or t == "boolean" or t == "number" or t == "string" then
        return obj
    end
end

Interop:RegisterHandler(HANDLER)