import { fromLua, toLua, registerHandler, callbacks } from "./handler";
import { objects, uniqueId } from "./object";

import "./handlers/binary";
import "./handlers/primitives";
import "./handlers/object";
import "./handlers/function";
import "./handlers/opaque";

window._interop_js_ = {
    registerLuaFunction(path, func) {
        const a = path.split(".");
        let o: any = window;
        while (a.length - 1) {
            const n = a.shift() as string;
            if (!(n in o)) o[n] = {};
            o = o[n];
        }
        o[a[0]] = fromLua(func);
    },
    collect(id) {
        // Delete the object with the given ID
        delete objects[id];
    },
    returnValue(callId, success, value) {
        if (callId in callbacks) {
            callbacks[callId](success, fromLua(value));
            delete callbacks[callId];
        }
    },
    async call(id, callId, ...args) {
        const func = objects[id] as (...args: any[]) => any;
        if (typeof func !== "function") {
            throw new Error(`Object with ID ${id} is not a function`);
        }
        try {
            const ret = await func(...args.map(fromLua));
            _interop_lua_.returnValue(callId, true, ret ? toLua(ret) : null);
        } catch (e) {
            _interop_lua_.returnValue(callId, false, String(e));
        }
    }
}

window.Interop = {
    uniqueId,
    registerHandler,
    fromLua,
    toLua
};