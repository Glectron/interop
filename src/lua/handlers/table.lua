local HANDLER = {}

HANDLER.Priority = 100

function HANDLER:From(obj)
    if type(obj) == "table" and not Interop:ObjectType(obj) then
        local newTbl = {}
        for k, v in pairs(obj) do
            newTbl[k] = Interop:FromJavascript(v)
        end
        return newTbl
    end
end

function HANDLER:To(obj)
    if type(obj) == "table" and not Interop:ObjectType(obj) then
        local newTbl = {}
        for k, v in pairs(obj) do
            newTbl[k] = Interop:ObjectType(v) and v or Interop:ToJavascript(v)
        end
        return newTbl
    end
end

Interop:RegisterHandler(HANDLER)