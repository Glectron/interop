local HANDLER = {}

HANDLER.Priority = 10

-- Pre-compute lookup table for valid ASCII control characters
local valid_control = {
    [9] = true,   -- tab
    [10] = true,  -- LF
    [13] = true,  -- CR
}

function HANDLER:IsBinary(s)
    -- Check for invalid UTF-8 first (fast native check)
    if not utf8.len(s) then
        return true
    end
    
    -- Sample first 512 bytes for long strings
    local sample_size = 512
    local check_len = #s > sample_size and sample_size or #s
    local byte = string.byte
    
    -- Check for control characters in sample
    for i = 1, check_len do
        local b = byte(s, i)
        if b == 127 or (b < 32 and not valid_control[b]) then
            return true
        end
    end
    
    return false
end

function HANDLER:From(obj)
    if Interop:ObjectType(obj) == "binary" then
        return util.Base64Decode(obj.data)
    end
end

function HANDLER:To(obj)
    if type(obj) == "string" and self:IsBinary(obj) then
        return Interop:CreateObject("binary", { data = util.Base64Encode(obj) })
    end
end

Interop:RegisterHandler(HANDLER)