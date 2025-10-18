import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY!;

export async function POST(req: Request) {
  try {
    if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
      return NextResponse.json({ ok:false, error:"Server misconfigured: SUPABASE env vars missing" }, { status: 500 });
    }

    const j = await req.json();

    // Minimal sanity checks (DB still the source of truth)
    const e164 = /^\+[1-9][0-9]{7,14}$/;
    if (!j?.country || !j?.state || !j?.fullname) {
      return NextResponse.json({ ok:false, error:"Missing required fields: country/state/fullname" }, { status:400 });
    }
    if (!e164.test(j?.mobile ?? "")) {
      return NextResponse.json({ ok:false, error:"Use E.164 for mobile (e.g., +919876543210)" }, { status:400 });
    }
    if (!e164.test(j?.recovery_e164 ?? "")) {
      return NextResponse.json({ ok:false, error:"Use E.164 for recovery_e164" }, { status:400 });
    }
    if (j.mobile === j.recovery_e164) {
      return NextResponse.json({ ok:false, error:"Mobile number and recovery mobile number cannot be same" }, { status:400 });
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data, error } = await supabase.rpc("api_add_connector_v1", {
      in_country: j.country,
      in_state: j.state,
      in_parent_ref: j.parent_ref ?? null,
      in_mobile_e164: j.mobile,
      in_fullname: j.fullname,
      in_email: j.email ?? null,
      in_short: (j.short ? String(j.short).toUpperCase() : null),
      in_recovery_e164: j.recovery_e164,
      in_extra: j.extra ?? {},
    });

    if (error) {
      return NextResponse.json({ ok:false, error: error.message }, { status:400 });
    }

    const row = Array.isArray(data) ? data[0] : data;
    return NextResponse.json({ ok:true, result: {
      id: row?.id,
      referral_code: row?.referral_code,
      connecta_id: row?.connecta_id,
      connectaID_full: row?.connectaid_full,
      level: row?.level,
      level_sequence: row?.level_sequence,
    }});
  } catch (e:any) {
    return NextResponse.json({ ok:false, error: e?.message ?? "Server error" }, { status:500 });
  }
}
