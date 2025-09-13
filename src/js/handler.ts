export const handlers: Handler[] = [];

export function registerHandler(handler: Handler) {
    handlers.push(handler);
    handlers.sort((a, b) => (a.priority ?? 0) - (b.priority ?? 0));
}

export function fromLua(obj: unknown): unknown {
    for (const handler of handlers) {
        const result = handler.from(obj);
        if (result !== undefined) {
            return result;
        }
    }
    return undefined;
}

export function toLua(obj: unknown): unknown {
    for (const handler of handlers) {
        const result = handler.to(obj);
        if (result !== undefined) {
            return result;
        }
    }
    return undefined;
}
