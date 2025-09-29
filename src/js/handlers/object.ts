import { finalizationRegistry } from "../gc";
import { fromLua, registerHandler, toLua } from "../handler";
import { createLuaObject, interopType } from "../object";

const handler: Handler = {
    priority: 100,
    from(obj: unknown): unknown {
        if (typeof obj === "object" && interopType(obj) === "table") {
            const newObj = Array.isArray(obj) ? [] : {};
            for (const k in obj) {
                const v = (obj as Record<any, any>)[k];
                (newObj as Record<any, any>)[k] = fromLua(v);
            }
            finalizationRegistry.register(newObj, (obj as any)._G_TableId);
            return newObj;
        }
        return undefined;
    },
    to(obj: unknown): unknown {
        if (typeof obj === "object") {
            const type = interopType(obj);
            if (type === null) {
                // JavaScript object, convert its properties
                const newObj = Array.isArray(obj) ? [] : {};
                for (const k in obj) {
                    const v = (obj as Record<any, any>)[k];
                    (newObj as Record<any, any>)[k] = interopType(v) !== null ? v : toLua(v);
                }
                return newObj;
            } else {
                // Lua object, let Lua return its original one
                return createLuaObject("table", {
                    id: (obj as any)._G_TableId
                });
            }
        }
        return undefined;
    }
}

registerHandler(handler);