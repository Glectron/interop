import { fromLua, toLua, registerHandler } from "./handler";
import { objects } from "./object";

import "./handlers/primitives";
import "./handlers/object";
import "./handlers/function";
import "./handlers/opaque";

window._interop_js_ = {
    registerLuaFunction(params: any[]) {
        const [path, func] = params;
        const a = path.split(".");
        let o: any = window;
        while (a.length - 1) {
            const n = a.shift();
            if (!(n in o)) o[n] = {};
            o = o[n];
        }
        o[a[0]] = fromLua(func);
    },
    collect(params: any[]) {
        const [id] = params;
        // Delete the object with the given ID
        delete objects[id];
    },
    call(params: any[]) {
        const [id, ...args] = params;
        const func = objects[id] as Function;
        if (typeof func !== "function") {
            throw new Error(`Object with ID ${id} is not a function`);
        }
        return func(...args.map(fromLua));
    }
}

window.Interop = {
    registerHandler,
    fromLua,
    toLua
};