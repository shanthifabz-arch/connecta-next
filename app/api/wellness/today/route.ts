// src/app/api/wellness/today/route.ts
import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";

function sb() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY!;
  return createClient(url, key, { auth: { persistSession: false } });
}

/**
 * GET /api/wellness/today?timezone=Asia/Kolkata&language=ta-IN
 * Returns today's active program for the timezone, windows, chosen audio, and start_time_local echo.
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

    // 1) Find today’s active program for the timezone
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

    // 3) Audio pick
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

    // 4) Echo today’s local start time for client-side scheduling
    const session_start_local = program.start_time_local; // "HH:mm:ss" from DB

    return NextResponse.json({
      ok: true,
      program,
      session_start_local,
      windows: windows ?? [],
      audio,
    });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: e?.message || "today failed" }, { status: 500 });
  }
}
