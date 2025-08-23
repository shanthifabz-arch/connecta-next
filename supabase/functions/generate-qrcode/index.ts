// index.ts for Supabase Edge Function (Deno)

import { encode } from "https://deno.land/x/qrcode/mod.ts";

export async function handler(req: Request): Promise<Response> {
  try {
    const url = new URL(req.url);
    const textToEncode = url.searchParams.get("text") || "CONNECTA Default QR";

    // Generate QR code PNG as Uint8Array
    const pngData: Uint8Array = await encode(textToEncode, { type: "png" });

    // Convert Uint8Array to base64 string
    const base64String = btoa(String.fromCharCode(...pngData));

    // Create data URL for the PNG image
    const qrDataUrl = `data:image/png;base64,${base64String}`;

    // Return JSON response with QR code data URL
    return new Response(JSON.stringify({ qrDataUrl }), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        "Cache-Control": "public, max-age=3600",
      },
    });
  } catch (error) {
    console.error("QR Code generation error:", error);
    return new Response(JSON.stringify({ error: "Failed to generate QR code" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
}
