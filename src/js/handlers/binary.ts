import { registerHandler } from "../handler";
import { createLuaObject, interopType } from "../object";

function hex_to_uint8array(hexString: string): Uint8Array {
    // Ensure the hex string has an even number of characters
    if (hexString.length % 2 !== 0) {
        throw new Error("Invalid hex string: Must have an even number of characters.");
    }

    const bytes = [];
    for (let i = 0; i < hexString.length; i += 2) {
        // Get a two-character substring (e.g., "68", "65", "ff")
        const byteHex = hexString.substring(i, i + 2);
        // Parse it as a base-16 number
        const byte = parseInt(byteHex, 16);
        if (isNaN(byte)) {
            throw new Error("Invalid character found in hex string.");
        }
        bytes.push(byte);
    }

    return new Uint8Array(bytes);
}

function uint8array_to_hex(uint8Array: Uint8Array): string {
    // Convert the Uint8Array to a regular array to use .map()
    return Array.from(uint8Array)
        // For each byte, convert it to a 2-digit hex string
        .map(byte => {
            // byte.toString(16) converts the number to hex
            // .padStart(2, '0') ensures it's always two characters (e.g., 7 -> "07")
            return byte.toString(16).padStart(2, '0');
        })
        // Join all the hex strings into a single string
        .join('');
}

const handler: Handler = {
    priority: 10,
    from(obj: unknown): unknown {
        if (interopType(obj) === "binary") {
            return hex_to_uint8array((obj as any).data);
        }
        return undefined;
    },
    to(obj: unknown): unknown {
        if (typeof obj === "object" && obj instanceof Uint8Array) {
            return createLuaObject("binary", {
                data: uint8array_to_hex(obj)
            });
        }
        return undefined;
    }
}

registerHandler(handler);