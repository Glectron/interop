import { randomString } from "./util";

export const objects: Record<string, object> = {}
export const wrappers = new WeakMap<object, string>();

export function uniqueId(): string {
    return randomString(10);
}

export function interopType(obj: any): string | null {
    if (typeof obj === "object" && "_G_InteropType" in obj) {
        return (obj as any)._G_InteropType;
    }
    return null;
}

export function createLuaObject(type: string, obj: object): object {
    (obj as Record<string, string>)["_G_InteropType"] = type;
    return obj;
}