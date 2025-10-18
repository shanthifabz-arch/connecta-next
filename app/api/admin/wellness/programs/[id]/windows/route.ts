// app/api/admin/wellness/programs/[id]/windows/route.ts
import { NextRequest, NextResponse } from "next/server";
import { getSupabaseServer } from "@/lib/supabase-server";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

type WindowRowIn = {
  window_index: number;   // 1-based index
  offset_sec: number;     // start offset in seconds
  duration_sec: number;   // duration in seconds
  enabled?: boolean;
};

// --- helpers ---------------------------------------------------------------

function getAdminToken() {
  return (process.env.WELLNESS_ADMIN_TOKEN ?? "").trim();
}

function extractProvidedToken(req: NextRequest) {
  const x = req.headers.get("x-admin-token");
  if (x && x.trim()) return x.trim();

  const auth = req.headers.get("authorization");
  if (auth && /^Bearer\s+/i.test(auth)) {
    return auth.replace(/^Bearer\s+/i, "").trim();
  }
  return "";
}

function assertAdminAuthorized(req: NextRequest) {
  // --- DEBUG SNIPPET (safe booleans only; dev mode only) ------------------
  if (process.env.NODE_ENV !== "production") {
    console.log(
      "[admin-auth] has x-admin-token:",
      !!req.headers.get("x-admin-token"),
      "has authorization:",
      !!req.headers.get("authorization")
    );
  }
  // -----------------------------------------------------------------------

  const expected = getAdminToken();
  if (!expected) {
    return NextResponse.json(
      { ok: false, error: "Server misconfigured: WELLNESS_ADMIN_TOKEN missing" },
      { status: 500 }
    );
  }
  const provided = extractProvidedToken(req);
  if (provided !== expected) {
    return NextResponse.json({ ok: false, error: "FORBIDDEN" }, { status: 403 });
  }
  return null;
}

// --- GET: list program windows -------------------------------------------

export async function GET(
  req: NextRequest,
  ctx: { params: Promise<{ id: string }> } // Next 15: params is a Promise
) {
  const authErr = assertAdminAuthorized(req);
  if (authErr) return authErr;

  try {
    const { id: programId } = await ctx.params;
    const supabase = getSupabaseServer();

    const { data, error } = await supabase
      .from("wellness_program_windows")
      .select("*")
      .eq("program_id", programId)
      .order("window_index", { ascending: true });

    if (error) {
      return NextResponse.json({ ok: false, error: error.message }, { status: 400 });
    }
    return NextResponse.json({ ok: true, windows: data ?? [] });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: e?.message || "GET failed" }, { status: 500 });
  }
}

// --- PUT: upsert program windows -----------------------------------------

export async function PUT(
  req: NextRequest,
  ctx: { params: Promise<{ id: string }> }
) {
  const authErr = assertAdminAuthorized(req);
  if (authErr) return authErr;

  try {
    const { id: programId } = await ctx.params;
    const body = (await req.json()) as WindowRowIn[] | any;

    if (!Array.isArray(body)) {
      return NextResponse.json({ ok: false, error: "Expected JSON array" }, { status: 400 });
    }

    const toNumber = (v: any) => (typeof v === "number" ? v : Number(v));

    // Normalize & validate
    const rows = body.map((r: WindowRowIn) => {
      const window_index = toNumber(r.window_index);
      const offset_sec = toNumber(r.offset_sec);
      const duration_sec = toNumber(r.duration_sec);

      return {
        program_id: programId,
        window_index,
        offset_sec,
        duration_sec,
        enabled: !!r.enabled,
      };
    });

    for (const r of rows) {
      if (!Number.isFinite(r.window_index) || r.window_index < 1) {
        return NextResponse.json(
          { ok: false, error: "window_index must be a positive integer" },
          { status: 400 }
        );
      }
      if (!Number.isFinite(r.offset_sec) || r.offset_sec < 0) {
        return NextResponse.json(
          { ok: false, error: "offset_sec must be a non-negative number" },
          { status: 400 }
        );
      }
      if (!Number.isFinite(r.duration_sec) || r.duration_sec <= 0) {
        return NextResponse.json(
          { ok: false, error: "duration_sec must be a positive number" },
          { status: 400 }
        );
      }
    }

    const supabase = getSupabaseServer();

    // Empty array = clear all rows for this program
    if (rows.length === 0) {
      const { error: delErr } = await supabase
        .from("wellness_program_windows")
        .delete()
        .eq("program_id", programId);

      if (delErr) {
        return NextResponse.json({ ok: false, error: delErr.message }, { status: 400 });
      }
      return NextResponse.json({ ok: true, windows: [] });
    }

    const { data, error } = await supabase
      .from("wellness_program_windows")
      .upsert(rows, { onConflict: "program_id,window_index" })
      .select("*")
      .order("window_index", { ascending: true });

    if (error) {
      return NextResponse.json({ ok: false, error: error.message }, { status: 400 });
    }
    return NextResponse.json({ ok: true, windows: data ?? [] });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: e?.message || "PUT failed" }, { status: 500 });
  }
}
