import { finalizationRegistry } from "../gc";
import { registerHandler } from "../handler";
import { createLuaObject, interopType, objects, wrappers } from "../object";
import { randomString } from "../util";

const handler: Handler = {
    priority: 200,
    from(obj: unknown): unknown {
        if (typeof obj === "object" && interopType(obj) === "opaque") {
            wrappers.set((obj as object), (obj as any).id);
            finalizationRegistry.register((obj as object), (obj as any).id);
            return obj;
        }
        return undefined;
    },
    to(obj: unknown): unknown {
        if (typeof obj === "object" && interopType(obj) === "opaque") {
            return obj;
        }

        // A Javascript object, wrap it as opaque
        const id = randomString(10);
        objects[id] = obj as object;
        return createLuaObject("opaque", { id });
    }
}

registerHandler(handler);