import { NextResponse } from "next/server";
import { getSupabaseServer } from "@/lib/supabase-server";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

const ADMIN = process.env.WELLNESS_ADMIN_TOKEN || "";

export async function GET(req: Request) {
  const token = req.headers.get("x-admin-token");
  if (!ADMIN || token !== ADMIN) {
    return NextResponse.json({ error: "FORBIDDEN" }, { status: 403 });
  }

  const { searchParams } = new URL(req.url);
  const language = searchParams.get("language") || undefined;
  const q = (searchParams.get("q") || "").trim();

  const supabase = getSupabaseServer();

  let query = supabase
    .from("wellness_master_items") // <-- change if your table name differs
    .select("id,title,language,is_visible,sort_index", { count: "exact" });

  if (language) query = query.eq("language", language);
  if (q)        query = query.ilike("title", `%${q}%`);

  query = query
    .order("sort_index", { ascending: true, nullsFirst: true })
    .order("id", { ascending: true });

  const { data, error, count } = await query;
  if (error) return NextResponse.json({ error: "DB_ERROR", details: error.message }, { status: 500 });

  return NextResponse.json({ total: count ?? (data?.length ?? 0), items: data ?? [] });
}
