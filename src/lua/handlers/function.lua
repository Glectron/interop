local HANDLER = {}

HANDLER.Priority = 150

function HANDLER:From(obj)
    if type(obj) == "table" and Interop:ObjectType(obj) == "function" then
        local id = obj.id
        if Interop.m_Objects[id] then
            -- Lua's function, return it
            return Interop.m_Objects[id]
        else
            -- Javascript's function, create a wrapper
            local ptbl = {}
            local func = function(...)
                local p = ptbl -- Hack for function GC
                local promise, resolve, reject = Interop:CreatePromise()
                local callId = Interop:UniqueID()
                Interop.m_ReturnCallbacks[callId] = function(success, result)
                    if success then
                        resolve(result)
                    else
                        reject(result)
                    end
                end
                Interop:RunJavascriptFunction("_interop_js_.call", obj.id, callId, ...)
                return promise
            end
            Interop:ListenForGC(ptbl, function()
                Interop:Collect(id)
            end)
            Interop.m_Wrappers[func] = obj.id
            return func
        end
    end
end

function HANDLER:To(obj)
    if type(obj) == "function" then
        if Interop.m_Wrappers[obj] then
            -- A wrapper of a JavaScript function
            return Interop:CreateJavascriptObject("function", { id = Interop.m_Wrappers[obj] })
        else
            local id = Interop:UniqueID()
            Interop.m_Objects[id] = obj
            return Interop:CreateJavascriptObject("function", { id = id })
        end
    end
end

Interop:RegisterHandler(HANDLER)