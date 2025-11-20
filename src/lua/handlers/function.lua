local HANDLER = {}

HANDLER.Priority = 150

function HANDLER:UsesSelf(func)
    -- Get function info (ensure it's a Lua function, not C)
    local info = debug_getinfo(func, "Su")
    if not info or info.what ~= "Lua" then
        return false  -- C functions or no debug info
    end

    -- Check the first parameter's name
    local param1 = debug_getlocal(func, 1)
    return param1 == "self"
end

function HANDLER:From(obj)
    if type(obj) == "table" and Interop:ObjectType(obj) == "function" then
        local id = obj.id
        local object = Interop:GetObject(id)
        if object then
            -- Lua's function, return it
            return object
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
                Interop:RunJavascriptFunction("_interop_js_.call", id, callId, ...)
                return promise
            end
            Interop:ListenForGC(ptbl, function()
                Interop:Collect(id)
            end)
            Interop.m_Wrappers[func] = id
            return func
        end
    end
end

function HANDLER:To(obj, context)
    if type(obj) == "function" then
        if Interop.m_Wrappers[obj] then
            -- A wrapper of a JavaScript function
            return Interop:CreateObject("function", { id = Interop.m_Wrappers[obj] })
        else
            local id = Interop:UniqueID()
            local data = { id = id }
            local objData = { }
            local parent = context.parentTable
            if parent and self:UsesSelf(obj) then
                data.selfObj = parent
                objData.selfObj = parent -- Keep a reference to the parent table for OnCollect
                Interop:RefObject(parent)
            end
            Interop:RegisterObject(id, obj, objData)
            return Interop:CreateObject("function", data)
        end
    end
end

function HANDLER:OnCollect(id, obj, data)
    if type(obj) == "function" then
        if data and data.selfObj then
            Interop:OnCollect(data.selfObj) -- Trigger a collection
        end
    end
end

Interop:RegisterHandler(HANDLER)
