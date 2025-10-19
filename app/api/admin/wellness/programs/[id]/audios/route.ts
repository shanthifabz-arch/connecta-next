// app/api/admin/wellness/programs/[id]/audios/route.ts
import { NextRequest, NextResponse } from "next/server";
import { getSupabaseServer } from "@/lib/supabase-server";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

type AudioRowIn = {
  language_code: string;
  audio_url: string;
  enabled?: boolean;
  volume?: number | null; // 0..1, or null
};

// --- helpers ---------------------------------------------------------------

function getAdminToken() {
  // Read at request time so hot env reloads are reflected immediately
  return (process.env.WELLNESS_ADMIN_TOKEN ?? "").trim();
}

function extractProvidedToken(req: NextRequest) {
  // Support either custom header or Authorization: Bearer ...
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
  return null; // authorized
}

// --- GET: list program audios --------------------------------------------

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
      .from("wellness_program_audios")
      .select("*")
      .eq("program_id", programId)
      .order("language_code", { ascending: true });

    if (error) {
      return NextResponse.json({ ok: false, error: error.message }, { status: 400 });
    }
    return NextResponse.json({ ok: true, audios: data ?? [] });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: e?.message || "GET failed" }, { status: 500 });
  }
}

// --- PUT: upsert program audios ------------------------------------------

export async function PUT(
  req: NextRequest,
  ctx: { params: Promise<{ id: string }> }
) {
  const authErr = assertAdminAuthorized(req);
  if (authErr) return authErr;

  try {
    const { id: programId } = await ctx.params;
    const body = (await req.json()) as AudioRowIn[] | any;

    if (!Array.isArray(body)) {
      return NextResponse.json({ ok: false, error: "Expected JSON array" }, { status: 400 });
    }

    // Normalize & validate
    const rows = body.map((r: AudioRowIn) => {
      const language_code = String(r.language_code ?? "").trim();
      const audio_url = String(r.audio_url ?? "").trim();

      let volume: number | null = null;
      if (typeof r.volume === "number") {
        volume = Math.max(0, Math.min(1, r.volume)); // clamp 0..1
      }

      return {
        program_id: programId,
        language_code,
        audio_url,
        enabled: !!r.enabled,
        volume,
      };
    });

    for (const r of rows) {
      if (!r.language_code) {
        return NextResponse.json(
          { ok: false, error: "language_code is required" },
          { status: 400 }
        );
      }
      if (!r.audio_url) {
        return NextResponse.json(
          { ok: false, error: "audio_url is required" },
          { status: 400 }
        );
      }
    }

    const supabase = getSupabaseServer();

    // Empty array = clear all rows for this program
    if (rows.length === 0) {
      const { error: delErr } = await supabase
        .from("wellness_program_audios")
        .delete()
        .eq("program_id", programId);

      if (delErr) {
        return NextResponse.json({ ok: false, error: delErr.message }, { status: 400 });
      }
      return NextResponse.json({ ok: true, audios: [] });
    }

    const { data, error } = await supabase
      .from("wellness_program_audios")
      .upsert(rows, { onConflict: "program_id,language_code" })
      .select("*")
      .order("language_code", { ascending: true });

    if (error) {
      return NextResponse.json({ ok: false, error: error.message }, { status: 400 });
    }
    return NextResponse.json({ ok: true, audios: data ?? [] });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: e?.message || "PUT failed" }, { status: 500 });
  }
}
