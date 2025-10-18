// app/api/admin/wellness/programs/route.ts
import { NextRequest, NextResponse } from "next/server";
import { getSupabaseServer } from "@/lib/supabase-server";


/**
 * GET  /api/admin/wellness/programs
 * POST /api/admin/wellness/programs
 */

export async function GET() {
  try {
    const supabase = getSupabaseServer();
    const { data, error } = await supabase
      .from("wellness_programs")
      .select("*")
      .order("created_at", { ascending: false });

    if (error) {
      return NextResponse.json({ ok: false, error: error.message }, { status: 400 });
    }
    return NextResponse.json({ ok: true, programs: data ?? [] });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: e?.message || "GET failed" }, { status: 500 });
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();

    // Minimal validation
    const payload = {
      name: String(body?.name || "").trim(),
      country_code: String(body?.country_code || "IN"),
      timezone: String(body?.timezone || "Asia/Kolkata"),
      default_language_code: String(body?.default_language_code || "en-IN"),
      start_time_local: String(body?.start_time_local || "05:00:00"),
      days_of_week: Array.isArray(body?.days_of_week) ? body.days_of_week : [1,2,3,4,5,6,7],
      is_active: !!body?.is_active,
    };

    if (!payload.name) {
      return NextResponse.json({ ok: false, error: "name is required" }, { status: 400 });
    }

    const supabase = getSupabaseServer();
    const { data, error } = await supabase
      .from("wellness_programs")
      .insert(payload)
      .select("*")
      .single();

    if (error) {
      return NextResponse.json({ ok: false, error: error.message }, { status: 400 });
    }
    return NextResponse.json({ ok: true, program: data });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: e?.message || "POST failed" }, { status: 500 });
  }
}
