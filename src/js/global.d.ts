interface Window {
    _interop_lua_: LuaInterface;
    _interop_js_: JSInterface;
    Interop: InteropInterface;
}

interface InteropObject {
    _G_InteropType: string;
}

type FunctionInteropObject = InteropObject & {
    id: string;
}

interface LuaInterface {
    /**
     * Call a Lua function with the given ID and arguments.
     * @param id The unique ID of the function to call.
     * @param callId The ID of the callback function to handle the return value.
     * @param args The arguments to pass to the function.
     */
    call(id: string, callId: string, ...args: any[]): any;
    /**
     * Pass the return value of a previously called JavaScript function back to Lua.
     * @param callId The ID of the call.
     * @param success Whether the call was successful.
     * @param value The return value or error string.
     */
    returnValue(callId: string, success: boolean, value: any): void;
    /**
     * Notify Lua to perform garbage collection on the object with the given ID.
     */
    collect(id: string): void;
}

interface JSInterface {
    /**
     * Called by Lua to register a Lua function as a callable JavaScript function.
     * @param params Parameters
     */
    registerLuaFunction(params: [path: string, func: FunctionInteropObject]): void;
    /**
     * Called by Lua to notify that a Lua object is no longer needed and can be garbage collected.
     * @param params Parameters
     */
    collect(params: [id: string]): void;
    /**
     * Called by Lua to return a value from a previously called Lua function.
     * @param params Parameters
     */
    returnValue(params: [callId: string, success: boolean, value: any]): void;
    /**
     * Called by Lua to call a JavaScript function with the given ID and arguments.
     * @param params Parameters
     */
    call(params: [func: string, callId: string, ...args: any[]]): any;
}

interface InteropInterface {
    uniqueId(): string;
    registerHandler(handler: Handler): void;
    fromLua(obj: unknown): unknown;
    toLua(obj: unknown): unknown;
}

interface Handler {
    priority?: number;
    from(obj: unknown): unknown | null;
    to(obj: unknown): unknown | null;
}

declare const _interop_lua_: LuaInterface;
