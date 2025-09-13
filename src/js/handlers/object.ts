import { fromLua, registerHandler, toLua } from "../handler";
import { interopType } from "../object";

const handler: Handler = {
    priority: 100,
    from(obj: unknown): unknown {
        if (typeof obj === "object" && interopType(obj) === null) {
            const newObj = Array.isArray(obj) ? [] : {};
            for (const k in obj) {
                const v = (obj as Record<any, any>)[k];
                (newObj as Record<any, any>)[k] = fromLua(v);
            }
            return newObj;
        }
        return undefined;
    },
    to(obj: unknown): unknown {
        if (typeof obj === "object" && interopType(obj) === null) {
            const newObj = Array.isArray(obj) ? [] : {};
            for (const k in obj) {
                const v = (obj as Record<any, any>)[k];
                (newObj as Record<any, any>)[k] = interopType(v) !== null ? v : toLua(v);
            }
            return newObj;
        }
        return undefined;
    }
}

registerHandler(handler);