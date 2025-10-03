local HANDLER = {}

HANDLER.Priority = 10

function HANDLER:IsBinary(s)
    -- Perform the control character check.
    for i = 1, #s do
        local byte = string.byte(s, i)
        if (byte < 32 and byte ~= 9 and byte ~= 10 and byte ~= 13) or byte == 127 then
            return true
        end
    end

    if not utf8.len(s) then
        -- utf8.len returned false, indicating an invalid UTF-8 sequence.
        return true
    end

    return false
end

function HANDLER:HexToString(hex_string)
    if hex_string == nil or #hex_string % 2 ~= 0 then
        return ""
    end
    return (hex_string:gsub('..', function(cc)
        return string.char(tonumber(cc, 16))
    end))
end

function HANDLER:From(obj)
    if Interop:ObjectType(obj) == "binary" then
        return self:HexToString(obj.data)
    end
end

function HANDLER:To(obj)
    if type(obj) == "string" and self:IsBinary(obj) then
        local hex_data = obj:gsub('.', function(c)
            return string.format('%02X', string.byte(c))
        end)
        return Interop:CreateObject("binary", { data = hex_data })
    end
end

Interop:RegisterHandler(HANDLER)