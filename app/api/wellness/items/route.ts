// app/api/wellness/items/route.ts
import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";

export const runtime = "nodejs";          // ensure Node runtime (not Edge)
export const dynamic = "force-dynamic";   // avoid caching admin responses

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const SUPABASE_ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const WELLNESS_ADMIN_TOKEN = process.env.WELLNESS_ADMIN_TOKEN || "";

// (optional) allow CORS if you’ll call this from a different origin
const withCors = (resp: NextResponse) => {
  resp.headers.set("Access-Control-Allow-Origin", "*");
  resp.headers.set("Access-Control-Allow-Headers", "Content-Type, x-admin-token");
  resp.headers.set("Access-Control-Allow-Methods", "GET, OPTIONS");
  return resp;
};

export async function OPTIONS() {
  return withCors(new NextResponse(null, { status: 204 }));
}

export async function GET(req: Request) {
  try {
    // Fail fast on env misconfig
    if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
      return NextResponse.json(
        { error: "CONFIG_ERROR", details: "Supabase URL or anon key missing" },
        { status: 500 }
      );
    }
    if (!WELLNESS_ADMIN_TOKEN && !SUPABASE_SERVICE_ROLE_KEY) {
      // Not fatal for public reads, but admin path will fail later
      console.warn("[wellness/items] Service-role path cannot work: missing WELLNESS_ADMIN_TOKEN or SUPABASE_SERVICE_ROLE_KEY");
    }

    const { searchParams } = new URL(req.url);

    const timezone    = searchParams.get("timezone") ?? "Asia/Kolkata";
    const language    = searchParams.get("language") ?? "en-IN";
    const onlyVisible = (searchParams.get("onlyVisible") ?? "true").toLowerCase() === "true";
    const q           = (searchParams.get("q") ?? "").trim();

    // Parse ints safely
    const toInt = (v: string | null) => {
      if (v == null) return undefined;
      const n = Number(v);
      return Number.isFinite(n) ? Math.trunc(n) : undefined;
    };
    const clamp = (n: number, min: number, max: number) => Math.min(max, Math.max(min, n));

    const limitParam  = toInt(searchParams.get("limit"));
    const limit       = clamp(limitParam ?? 50, 1, 200);

    const pageParam     = toInt(searchParams.get("page"));
    const pageSizeParam = toInt(searchParams.get("pageSize"));
    const usePageMode   = pageParam !== undefined || pageSizeParam !== undefined;

    const page          = usePageMode ? clamp(pageParam ?? 1, 1, 1_000_000) : 1;
    const pageSize      = usePageMode ? clamp(pageSizeParam ?? limit, 1, 200) : limit;

    const offsetParam   = toInt(searchParams.get("offset"));
    const offset        = usePageMode ? (page - 1) * pageSize : clamp(offsetParam ?? 0, 0, 10_000_000);
    const pageLimit     = usePageMode ? pageSize : limit;

    // Auth: anon by default; service-role if onlyVisible=false AND caller provides header
    let supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

    if (!onlyVisible) {
      const adminHeader = req.headers.get("x-admin-token");
      if (!WELLNESS_ADMIN_TOKEN || adminHeader !== WELLNESS_ADMIN_TOKEN || !SUPABASE_SERVICE_ROLE_KEY) {
        return withCors(
          NextResponse.json(
            { error: "FORBIDDEN", details: "Admin token required for onlyVisible=false" },
            { status: 403 }
          )
        );
      }
      supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    }

    let query = supabase
      .from("wellness_items")
      .select("id,title,is_visible,language,sort_index", { count: "exact" })
      .eq("language", language);

    if (onlyVisible) query = query.eq("is_visible", true);
    if (q) query = query.ilike("title", `%${q}%`);

    query = query
      .order("sort_index", { ascending: true, nullsFirst: true })
      .order("id", { ascending: true })
      .range(offset, offset + pageLimit - 1);

    const { data, error, count } = await query;

    if (error) {
      console.error("[wellness/items] Supabase error:", error.message);
      return withCors(
        NextResponse.json({ error: "DB_ERROR", details: error.message }, { status: 500 })
      );
    }

    const items = (data ?? []).map((r: any) => ({
      id: r.id,
      title: r.title,
      isVisible: r.is_visible,
      language: r.language,
    }));

    const total = count ?? 0;
    const effectivePageSize = pageLimit;
    const totalPages = effectivePageSize > 0 ? Math.max(1, Math.ceil(total / effectivePageSize)) : 1;
    const currentPage = usePageMode ? page : Math.floor(offset / effectivePageSize) + 1;

    const resp = NextResponse.json({
      timezone,
      language,
      q,
      onlyVisible,
      limit: pageLimit,
      offset,
      page: currentPage,
      pageSize: effectivePageSize,
      total,
      totalPages,
      hasNext: currentPage < totalPages,
      hasPrev: currentPage > 1,
      items,
    });

    if (onlyVisible) {
      resp.headers.set("Cache-Control", "public, max-age=30, s-maxage=60, stale-while-revalidate=120");
    } else {
      resp.headers.set("Cache-Control", "no-store");
    }

    return withCors(resp);
  } catch (e: any) {
    console.error("[wellness/items] Unexpected error:", e?.message ?? e);
    return withCors(
      NextResponse.json({ error: "UNEXPECTED", details: e?.message ?? String(e) }, { status: 500 })
    );
  }
}
