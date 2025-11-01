Interop.m_JavascriptQueue = nil

function Interop:BeginTransaction()
    self.m_JavascriptQueue = {}
end

function Interop:CancelTransaction()
    self.m_JavascriptQueue = nil
end

function Interop:EndTransaction()
    if not self.m_JavascriptQueue then return end
    local js = "{" .. table_concat(self.m_JavascriptQueue, "}{") .. "}"
    self.m_JavascriptQueue = nil
    if not self.m_DHTML then return end
    self.m_DHTML:RunJavascript(js)
end

function Interop:RunJavascript(js)
    if self.m_JavascriptQueue then
        table_insert(self.m_JavascriptQueue, js)
    else
        if not self.m_DHTML then return end
        self.m_DHTML:RunJavascript(js)
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