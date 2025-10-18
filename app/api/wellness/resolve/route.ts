// src/app/api/wellness/resolve/route.ts
import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";

function sb() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY!;
  return createClient(url, key, { auth: { persistSession: false } });
}

/**
 * GET /api/wellness/resolve?timezone=Asia/Kolkata&language=ta-IN
 * Returns an active program for the timezone, its windows, and the best audio for the requested language.
 */
export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const tz = (searchParams.get("timezone") || "").trim();
    const lang = (searchParams.get("language") || "").trim();

    if (!tz) {
      return NextResponse.json({ ok: false, error: "timezone required" }, { status: 400 });
    }

    const supabase = sb();

    // 1) Pick the first active program for this timezone (you can later add country/lang filtering if needed)
    const { data: programs, error: pErr } = await supabase
      .from("wellness_programs")
      .select("*")
      .eq("timezone", tz)
      .eq("is_active", true)
      .order("created_at", { ascending: false })
      .limit(1);

    if (pErr) {
      return NextResponse.json({ ok: false, error: pErr.message }, { status: 400 });
    }
    const program = programs?.[0];
    if (!program) {
      return NextResponse.json({ ok: true, program: null, windows: [], audio: null });
    }

    // 2) Windows
    const { data: windows, error: wErr } = await supabase
      .from("wellness_program_windows")
      .select("*")
      .eq("program_id", program.id)
      .order("window_index", { ascending: true });

    if (wErr) {
      return NextResponse.json({ ok: false, error: wErr.message }, { status: 400 });
    }

    // 3) Audio pick: exact language if enabled, else default_language_code if enabled, else null
    let audio: any = null;
    if (lang) {
      const { data: ex, error: exErr } = await supabase
        .from("wellness_program_audios")
        .select("*")
        .eq("program_id", program.id)
        .eq("language_code", lang)
        .eq("enabled", true)
        .maybeSingle();
      if (exErr) {
        return NextResponse.json({ ok: false, error: exErr.message }, { status: 400 });
      }
      if (ex) audio = ex;
    }
    if (!audio) {
      const { data: def, error: dErr } = await supabase
        .from("wellness_program_audios")
        .select("*")
        .eq("program_id", program.id)
        .eq("language_code", program.default_language_code)
        .eq("enabled", true)
        .maybeSingle();
      if (dErr) {
        return NextResponse.json({ ok: false, error: dErr.message }, { status: 400 });
      }
      audio = def ?? null;
    }

    return NextResponse.json({ ok: true, program, windows: windows ?? [], audio });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: e?.message || "resolve failed" }, { status: 500 });
  }
}
