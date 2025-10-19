import { NextRequest, NextResponse } from "next/server";
import { supabaseAdmin } from "@/src/lib/supabaseAdmin";

const BUSINESS_NUMBER_E164 = process.env.BUSINESS_NUMBER_E164!; // e.g., +919876543210

export async function GET(req: NextRequest, { params }: { params: { token: string } }) {
  const token = params.token;

  try {
    // Log click (best-effort; don't block redirect)
    await supabaseAdmin.from("events").insert({
      token,
      type: "invite_clicked",
      phone_e164: null,
      meta: { ip: (req as any).ip || "unknown", ua: req.headers.get("user-agent") },
    });
  } catch (e) {
    console.error("events insert failed (non-fatal)", e);
  }

  // (Optional) validate token exists; if not, redirect to a friendly page
  try {
    const { data: inv } = await supabaseAdmin
      .from("invitations")
      .select("token")
      .eq("token", token)
      .maybeSingle();
    if (!inv) {
      return NextResponse.redirect(new URL("/invalid-invite", process.env.APP_BASE_URL!), 302);
    }
  } catch (e) {
    // ignore and still redirect to WA
  }

  const joinText = encodeURIComponent(`JOIN ${token}`);
  const numberDigits = BUSINESS_NUMBER_E164.replace("+", ""); // wa.me expects digits only
  const wa = `https://wa.me/${encodeURIComponent(numberDigits)}?text=${joinText}`;
  return NextResponse.redirect(wa, 302);
}
