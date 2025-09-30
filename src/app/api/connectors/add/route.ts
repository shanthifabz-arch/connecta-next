import { NextResponse } from "next/server";
import { addConnectorSchema } from "@/lib/validation/connectors";
import { createClient } from "@supabase/supabase-js";

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY!; // server-only

export async function POST(req: Request) {
  try {
    const json = await req.json();
    const parsed = addConnectorSchema.parse(json);

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data, error } = await supabase.rpc("api_add_connector_v1", {
      in_country: parsed.country,
      in_state: parsed.state,
      in_parent_ref: parsed.parent_ref ?? null,
      in_mobile_e164: parsed.mobile,
      in_fullname: parsed.fullname,
      in_email: parsed.email ?? null,
      in_short: parsed.short ?? null,
      in_recovery_e164: parsed.recovery_e164,
      in_extra: parsed.extra ?? {},
    });

    if (error) {
      return NextResponse.json({ ok: false, error: error.message }, { status: 400 });
    }

    const row = Array.isArray(data) ? data[0] : data;

    return NextResponse.json({
      ok: true,
      result: {
        id: row?.id,
        referral_code: row?.referral_code,
        connecta_id: row?.connecta_id,
        connectaID_full: row?.connectaid_full,
        level: row?.level,
        level_sequence: row?.level_sequence,
      },
    });
  } catch (e: any) {
    const msg = e?.issues?.[0]?.message ?? e?.message ?? "Server error";
    const code = msg.includes("E.164") || msg.includes("same") ? 400 : 500;
    return NextResponse.json({ ok: false, error: msg }, { status: code });
  }
}
