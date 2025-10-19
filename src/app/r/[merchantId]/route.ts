import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import crypto from "crypto";

/**
 * GET /r/:merchantId?ref=<global_connecta_id>
 * - Reads merchant (must be availability='open' and have deeplink_template)
 * - Generates click_ref, logs to affiliates_clicks
 * - Replaces {connector} and {click} in deeplink_template
 * - 302 redirects to final url
 *
 * Security:
 * - Uses SERVICE ROLE key so inserts work for any visitor (no client auth needed).
 * - Do NOT expose this key to the client; Next.js route code runs server-side.
 */

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY!; // server-only

// Server-only client (service role)
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

function makeClickRef() {
  // short, url-safe token
  return "ck_" + crypto.randomBytes(6).toString("base64url");
}

export async function GET(req: NextRequest, { params }: { params: { merchantId: string } }) {
  try {
    const merchantId = params.merchantId;
    const { searchParams } = new URL(req.url);

    // IMPORTANT: this is the CONNECTA global ID (connectors.global_connecta_id)
    const connector = (searchParams.get("ref") || "").trim();

    if (!merchantId) {
      return NextResponse.json({ error: "Missing merchantId" }, { status: 400 });
    }
    if (!connector) {
      return NextResponse.json({ error: "Missing ref (connector global id)" }, { status: 400 });
    }

    // Fetch merchant
    const { data: merchant, error: mErr } = await supabase
      .from("affiliates_merchants")
      .select("id, availability, deeplink_template")
      .eq("id", merchantId)
      .single();

    if (mErr || !merchant) {
      return NextResponse.json({ error: "Merchant not found" }, { status: 404 });
    }
    if (merchant.availability !== "open") {
      return NextResponse.json({ error: "Merchant is paused/unavailable" }, { status: 400 });
    }
    if (!merchant.deeplink_template) {
      return NextResponse.json({ error: "Merchant has no deeplink template configured" }, { status: 400 });
    }

    // Create and log click
    const clickRef = makeClickRef();
    const ip = (req.headers.get("x-forwarded-for") || "").split(",")[0]?.trim() || null;
    const ua = req.headers.get("user-agent") || "";

    const { error: insErr } = await supabase.from("affiliates_clicks").insert({
      click_ref: clickRef,
      merchant_id: merchant.id,
      connector_global_id: connector,
      ip,
      ua,
    });
    if (insErr) {
      // We keep going, but report the issue for observability
      console.error("affiliates_clicks insert failed:", insErr.message);
    }

    // Build final target URL
    const finalUrl = merchant.deeplink_template
      .replaceAll("{connector}", encodeURIComponent(connector))
      .replaceAll("{click}", encodeURIComponent(clickRef));

    // Validate URL format (avoid throwing on bad templates)
    try {
      // will throw if invalid
      new URL(finalUrl);
    } catch {
      return NextResponse.json({ error: "Bad deeplink_template for merchant" }, { status: 400 });
    }

    // Redirect to partner
    return NextResponse.redirect(finalUrl, { status: 302 });
  } catch (e: any) {
    console.error("Redirect error:", e);
    return NextResponse.json({ error: "Unexpected error" }, { status: 500 });
  }
}
