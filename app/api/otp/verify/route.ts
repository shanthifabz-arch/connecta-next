import { NextResponse } from "next/server";
export const runtime = "nodejs";

const MSG91_BASE = "https://control.msg91.com/api/v5";
const isE164 = (m: string) => /^\+\d{6,15}$/.test(m);

export async function POST(req: Request) {
  try {
    const { mobile, otp } = (await req.json().catch(() => ({}))) as {
      mobile?: string;
      otp?: string;
    };

    if (!mobile || !otp) {
      return NextResponse.json(
        { error: "Missing mobile or otp" },
        { status: 400 }
      );
    }
    if (!isE164(mobile)) {
      return NextResponse.json(
        { error: "Mobile must be E.164 (+<country><digits>)" },
        { status: 400 }
      );
    }
    if (typeof otp !== "string" || !/^\d{4,8}$/.test(otp)) {
      return NextResponse.json({ error: "Invalid OTP format" }, { status: 400 });
    }

    const key = process.env.MSG91_API_KEY;
    if (!key) {
      return NextResponse.json(
        { error: "MSG91 key not configured" },
        { status: 500 }
      );
    }

    const r = await fetch(`${MSG91_BASE}/otp/verify`, {
      method: "POST",
      headers: { authkey: key!, "Content-Type": "application/json" },
      body: JSON.stringify({ mobile, otp }),
    });

    const data = await r.json().catch(() => ({}));
    if (!r.ok) {
      return NextResponse.json(
        { error: data?.message || data?.error || `MSG91_HTTP_${r.status}` },
        { status: 401 }
      );
    }

    return NextResponse.json({ ok: true }, { status: 200 });
  } catch (e: any) {
    return NextResponse.json(
      { error: e?.message || "OTP verify failed" },
      { status: 500 }
    );
  }
}

export async function GET() {
  return NextResponse.json({ error: "Method not allowed" }, { status: 405 });
}
