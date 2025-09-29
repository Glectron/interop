function Interop:CreatePromise()
    local resolved = false
    local rejected = false
    local value = nil
    local err = nil
    local promise = {}
    function promise:Then(onResolve)
        if resolved then
            if onResolve then onResolve(value) end
        else
            self._onResolve = onResolve
        end
        return self
    end
    function promise:Catch(onReject)
        if rejected then
            if onReject then onReject(err) end
        else
            self._onReject = onReject
        end
        return self
    end
    function promise:Final(onFinal)
        if resolved or rejected then
            if onFinal then onFinal() end
        else
            self._onFinal = onFinal
        end
        return self
    end
    function resolve(val)
        if not resolved and not rejected then
            resolved = true
            value = val
            if promise._onResolve then
                promise._onResolve(value)
            end
            if promise._onFinal then
                promise._onFinal()
            end
        end
    end
    function reject(e)
        if not resolved and not rejected then
            rejected = true
            err = e
            if promise._onReject then
                promise._onReject(err)
            end
            if promise._onFinal then
                promise._onFinal()
            end
        end
    end
    return promise, resolve, reject
end