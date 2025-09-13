interface Window {
    _interop_lua_: LuaInterface;
    _interop_js_: JSInterface;
    Interop: InteropInterface;
}

interface LuaInterface {
    /**
     * Call a Lua function with the given ID and arguments.
     * @param id The unique ID of the function to call.
     * @param args The arguments to pass to the function.
     */
    call(id: string, ...args: any[]): any;
    /**
     * Notify Lua to perform garbage collection on the object with the given ID.
     */
    collect(id: string): void;
}

interface JSInterface {
    /**
     * Called by Lua to register a Lua function as a callable JavaScript function.
     * @param params Parameters: [path: string, func: Function]
     */
    registerLuaFunction(params: any[]): void;
    /**
     * Called by Lua to notify that a Lua object is no longer needed and can be garbage collected.
     * @param params Parameters: [id: string]
     */
    collect(params: any[]): void;
    /**
     * Called by Lua to call a JavaScript function with the given ID and arguments.
     * @param params Parameters: [func: Function, ...args: any[]]
     */
    call(params: any[]): any;
}

interface InteropInterface {
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
