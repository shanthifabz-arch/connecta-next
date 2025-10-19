import { NextResponse } from "next/server";

export async function POST(req: Request) {
  try {
    const { referralCode = "", mobile = "" } = await req.json();

    if (!referralCode) return NextResponse.json({ ok:false, error:"Missing referralCode" }, { status:400 });
    if (!mobile)      return NextResponse.json({ ok:false, error:"Missing mobile" }, { status:400 });

    // TODO: Replace with your real Supabase check (kept stubbed for smoke test)
    return NextResponse.json({ ok: true });
  } catch (e:any) {
    return NextResponse.json({ ok:false, error: e?.message ?? "Server error" }, { status:500 });
  }
}