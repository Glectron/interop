import { registerHandler } from "../handler";
import { createLuaObject, interopType } from "../object";

function base64_to_uint8array(base64String: string): Uint8Array {
    // Use native atob for decoding (extremely fast)
    const binaryString = atob(base64String);
    const len = binaryString.length;
    const bytes = new Uint8Array(len);
    
    for (let i = 0; i < len; i++) {
        bytes[i] = binaryString.charCodeAt(i);
    }
    
    return bytes;
}

function uint8array_to_base64(uint8Array: Uint8Array): string {
    // Convert Uint8Array to binary string
    let binaryString = '';
    const len = uint8Array.length;
    
    // Process in chunks to avoid stack overflow on large arrays
    const chunkSize = 8192;
    for (let i = 0; i < len; i += chunkSize) {
        const chunk = uint8Array.subarray(i, Math.min(i + chunkSize, len));
        binaryString += String.fromCharCode.apply(null, Array.from(chunk));
    }
    
    // Use native btoa for encoding (extremely fast)
    return btoa(binaryString);
}

const handler: Handler = {
    priority: 10,
    from(obj: unknown): unknown {
        if (interopType(obj) === "binary") {
            return base64_to_uint8array((obj as any).data);
        }
        return undefined;
    },
    to(obj: unknown): unknown {
        if (typeof obj === "object" && obj instanceof Uint8Array) {
            return createLuaObject("binary", {
                data: uint8array_to_base64(obj)
            });
        }
        return undefined;
    }
}

registerHandler(handler);