import { registerHandler } from "../handler";

const handler: Handler = {
    priority: 10,
    from(obj: unknown): unknown {
        if (typeof obj === "boolean" || typeof obj === "number" || typeof obj === "string" || obj === null) {
            return obj;
        }
        return undefined;
    },
    to(obj: unknown): unknown {
        if (typeof obj === "bigint") {
            return obj.toString();
        }
        if (typeof obj === "boolean" || typeof obj === "number" || typeof obj === "string" || typeof obj === "undefined" || obj === null) {
            return obj;
        }
        return undefined;
    }
}

registerHandler(handler);