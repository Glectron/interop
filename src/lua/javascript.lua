Interop.m_JavascriptQueue = nil

function Interop:BeginTransaction()
    self.m_JavascriptQueue = {}
end

function Interop:CancelTransaction()
    self.m_JavascriptQueue = nil
end

function Interop:EndTransaction()
    local queue = self.m_JavascriptQueue
    if not queue then return end
    local js = "{" .. table_concat(queue, "}{") .. "}"
    self.m_JavascriptQueue = nil
    local dhtml = self.m_DHTML
    if not IsValid(dhtml) then return end
    dhtml:RunJavascript(js)
end

function Interop:RunJavascript(js)
    local queue = self.m_JavascriptQueue
    if queue then
        table_insert(queue, js)
    else
        local dhtml = self.m_DHTML
        if not IsValid(dhtml) then return end
        dhtml:RunJavascript(js)
    end
end

function Interop:BuildJavascriptCallSignature(func, ...)
    local parameters = {...}
    local p = {}
    for _, v in ipairs(parameters) do
        table_insert(p, self:ToJavascript(v))
    end
    local json = util_TableToJSON(p)
    return string_format("%s(...%s)", func, json)
end

function Interop:RunJavascriptFunction(func, ...)
    self:RunJavascript(self:BuildJavascriptCallSignature(func, ...))
end
