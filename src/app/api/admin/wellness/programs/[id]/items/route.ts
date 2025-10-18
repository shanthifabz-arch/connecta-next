// src/app/api/admin/wellness/programs/[id]/items/route.ts
import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";

function sb() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { persistSession: false } }
  );
}

type ProgramItemIn = {
  position_index: number;       // 1..50
  master_code: string;          // code from master
  marks?: number | null;
  require_code?: boolean;
  visible?: boolean;
  duration_min?: number | null;
  start_offset_sec?: number | null;
};

export async function GET(
  _req: NextRequest,
  ctx: { params: { id: string } }
) {
  try {
    const programId = ctx.params.id;
    const s = sb();

    const { data, error } = await s
      .from("wellness_program_items")
      .select("*")
      .eq("program_id", programId)
      .order("position_index", { ascending: true });

    if (error) return NextResponse.json({ ok: false, error: error.message }, { status: 400 });
    return NextResponse.json({ ok: true, items: data ?? [] });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: e?.message || "GET failed" }, { status: 500 });
  }
}

export async function PUT(
  req: NextRequest,
  ctx: { params: { id: string } }
) {
  try {
    const programId = ctx.params.id;
    const body = (await req.json()) as ProgramItemIn[] | any;
    if (!Array.isArray(body)) {
      return NextResponse.json({ ok: false, error: "Expected JSON array" }, { status: 400 });
    }

    // Clean + validate
    const cleaned: ProgramItemIn[] = body.map((r: any) => ({
      position_index: Number(r.position_index),
      master_code: String(r.master_code || "").trim(),
      marks: r.marks === null || r.marks === undefined ? null : Number(r.marks),
      require_code: !!r.require_code,
      visible: r.visible === undefined ? true : !!r.visible,
      duration_min: r.duration_min === null || r.duration_min === undefined ? null : Number(r.duration_min),
      start_offset_sec: r.start_offset_sec === null || r.start_offset_sec === undefined ? null : Number(r.start_offset_sec),
    }));

    for (const r of cleaned) {
      if (!(r.position_index >= 1 && r.position_index <= 50)) {
        return NextResponse.json({ ok: false, error: "position_index must be 1..50" }, { status: 400 });
      }
      if (!r.master_code) {
        return NextResponse.json({ ok: false, error: "master_code required" }, { status: 400 });
      }
    }

    const s = sb();

    // Strategy: replace all rows for this program with the submitted set
    const { error: delErr } = await s
      .from("wellness_program_items")
      .delete()
      .eq("program_id", programId);

    if (delErr) return NextResponse.json({ ok: false, error: delErr.message }, { status: 400 });

    const rows = cleaned.map((r) => ({ ...r, program_id: programId }));
    if (rows.length) {
      const { data, error } = await s
        .from("wellness_program_items")
        .insert(rows)
        .select("*")
        .order("position_index", { ascending: true });

      if (error) return NextResponse.json({ ok: false, error: error.message }, { status: 400 });
      return NextResponse.json({ ok: true, items: data ?? [] });
    }

    return NextResponse.json({ ok: true, items: [] });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: e?.message || "PUT failed" }, { status: 500 });
  }
}
