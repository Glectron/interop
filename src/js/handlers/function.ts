import { finalizationRegistry } from "../gc";
import { registerHandler, toLua } from "../handler";
import { createLuaObject, interopType, objects, wrappers } from "../object"
import { randomString } from "../util";

const handler: Handler = {
    priority: 150,
    from(obj: unknown): unknown {
        if (typeof obj === "object" && interopType(obj) === "function") {
            const id = (obj as any).id;
            if (id in objects) {
                // A Javascript function, return it
                return objects[id];
            } else {
                // A Lua function, wrap it
                const func = function(...args: any[]) {
                    const parameters = [];
                    for (let i = 0;i<args.length;i++) {
                        parameters.push(toLua(args[i]));
                    }
                    _interop_lua_.call(id, ...parameters);
                };
                wrappers.set(func, id);
                finalizationRegistry.register(func, id);
                return func;
            }
        }
        return undefined;
    },
    to(obj: unknown): unknown {
        if (typeof obj === "function") {
            if (wrappers.has(obj)) {
                // A Lua function, return as is.
                return createLuaObject("function", {
                    id: wrappers.get(obj)
                });
            } else {
                // A Javascript function, wrap it
                const id = randomString(10);
                objects[id] = obj;
                return createLuaObject("function", { id });
            }
        }
        return undefined;
    }
}

registerHandler(handler);