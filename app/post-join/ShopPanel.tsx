"use client";

import React, { useEffect, useMemo, useState } from "react";
import { createClient } from "@supabase/supabase-js";

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL as string,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY as string
);

/* =========================
   Types (mirror future APIs)
========================= */
type Scope = "me" | "l1" | "l2" | "l3" | "downline";
type Availability = "all" | "open" | "paused";

type SearchFilters = {
  q: string;
  category: string;        // slug or display for now
  discountMin: number;     // %
  location: string;        // city/state free text
  availability: Availability;
};

type Merchant = {
  id: string;
  name: string;
  logoUrl?: string;
  discountPct: number;
  tags: string[];
  category: string;
  location: string;
  availability: Availability;
  landingUrl?: string;     // where we’ll redirect on CTA
};

type ActivityRow = {
  date: string;            // ISO date (day)
  scope: Scope;            // who’s included
  clicks: number;
  carts: number;
  purchasesCount: number;
  purchasesValue: number;  // INR
};

type TopMerchant = {
  merchantId: string;
  merchantName: string;
  purchasesCount: number;
  purchasesValue: number;  // INR
};

/* =========================
   API STUBS (wire later)
========================= */
function startOfDayISO(d: Date) {
  const x = new Date(d);
  x.setHours(0, 0, 0, 0);
  return x.toISOString();
}

async function api_affiliates_search(params: Partial<SearchFilters>): Promise<Merchant[]> {
  // Build Supabase query to public.affiliates_merchants
  let q = supabase.from("affiliates_merchants").select("*");

  // Availability / Category
  if (params.availability && params.availability !== "all") q = q.eq("availability", params.availability);
  if (params.category && params.category !== "all") q = q.eq("category", params.category);

  // Simple text search against name + category; expand as needed
  if (params.q && params.q.trim()) {
    const term = params.q.trim();
    // name/location if you add that column later
    q = q.or(`name.ilike.%${term}%,category.ilike.%${term}%`);
  }

  // Order newest first
  const { data, error } = await q.order("created_at", { ascending: false });
  if (error) throw error;

  // Map DB → ShopPanel Merchant shape
  return (data || []).map((m: any) => ({
    id: m.id,
    name: m.name,
    logoUrl: m.logo_url || "",
    discountPct: 0, // you don’t store discount_pct here; keep 0 or add a column later
    tags: [],       // optional; populate if you add tags[] later
    category: m.category || "others",
    location: "Pan-India", // optional placeholder
    availability: m.availability === "open" ? "open" : "paused",
    landingUrl: undefined, // we’ll open via /r/:id instead
  }));
}


async function api_affiliates_activity(params: {
  scope: Scope;
  from: string;
  to: string;
}): Promise<{ rows: ActivityRow[]; top: TopMerchant[] }> {
  // generate a few days of mock rows
  const out: ActivityRow[] = [];
  const start = new Date(params.from).getTime();
  const end = new Date(params.to).getTime();
  const dayMs = 86400000;
  for (let t = start; t <= end; t += dayMs) {
    const seed = (t / dayMs) % 10;
    const clicks = Math.round((seed + 3) * 7);
    const carts = Math.round((seed % 5) + 2);
    const pc = Math.max(0, Math.round((seed % 4))); // purchases count
    const pv = pc * Math.round(1200 + seed * 250);
    out.push({
      date: new Date(t).toISOString(),
      scope: params.scope,
      clicks,
      carts,
      purchasesCount: pc,
      purchasesValue: pv,
    });
  }

  const top: TopMerchant[] = [
    { merchantId: "m2", merchantName: "StyleKart", purchasesCount: 21, purchasesValue: 72600 },
    { merchantId: "m1", merchantName: "FlipDeal",  purchasesCount: 17, purchasesValue: 55200 },
    { merchantId: "m4", merchantName: "GroceryGo", purchasesCount: 10, purchasesValue: 19800 },
  ];

  return { rows: out, top };
}

async function api_affiliates_track_click(_params: { merchantId: string }) {
  // stub: pretend stored and return a redirect token if needed
  return { ok: true };
}

/* =========================
   Helpers
========================= */
function formatINR(n: number) {
  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    maximumFractionDigits: 0,
  }).format(n);
}

function daysBackISOString(days: number) {
  const d = new Date(Date.now() - days * 86400000);
  return startOfDayISO(d).slice(0, 10); // yyyy-mm-dd
}

/* =========================
   Component
========================= */
export default function ShopPanel({ refCode }: { refCode: string }) {
  /* ---------- Search state ---------- */
  const [filters, setFilters] = useState<SearchFilters>({
    q: "",
    category: "all",
    discountMin: 0,
    location: "",
    availability: "all",
  });
  const [merchants, setMerchants] = useState<Merchant[]>([]);
  const [searching, setSearching] = useState(false);

  /* ---------- Activity state ---------- */
  const [scope, setScope] = useState<Scope>("me");
  const [from, setFrom] = useState(daysBackISOString(29));
  const [to, setTo] = useState(daysBackISOString(0));
  const [rows, setRows] = useState<ActivityRow[]>([]);
  const [top, setTop] = useState<TopMerchant[]>([]);
  const [loadingActivity, setLoadingActivity] = useState(false);

  /* ---------- Effects ---------- */
  useEffect(() => {
    let alive = true;
    (async () => {
      setSearching(true);
      try {
        const res = await api_affiliates_search(filters);
        if (alive) setMerchants(res);
      } finally {
        if (alive) setSearching(false);
      }
    })();
    return () => { alive = false; };
  }, [filters]);

  useEffect(() => {
    let alive = true;
    (async () => {
      setLoadingActivity(true);
      try {
        const { rows: r, top: t } = await api_affiliates_activity({
          scope,
          from: new Date(from).toISOString(),
          to: new Date(to).toISOString(),
        });
        if (alive) {
          setRows(r);
          setTop(t);
        }
      } finally {
        if (alive) setLoadingActivity(false);
      }
    })();
    return () => { alive = false; };
  }, [scope, from, to]);

  /* ---------- Derived ---------- */
  const totalClicks = useMemo(() => rows.reduce((s, r) => s + r.clicks, 0), [rows]);
  const totalCarts = useMemo(() => rows.reduce((s, r) => s + r.carts, 0), [rows]);
  const totalPurchases = useMemo(() => rows.reduce((s, r) => s + r.purchasesCount, 0), [rows]);
  const totalValue = useMemo(() => rows.reduce((s, r) => s + r.purchasesValue, 0), [rows]);

  /* ---------- Handlers ---------- */
 async function visitMerchant(m: Merchant) {
  const connector = refCode; // this is global_connecta_id passed from page.tsx
  const url = `/r/${m.id}?ref=${encodeURIComponent(connector || "")}`;
  window.open(url, "_blank");
}


  /* ---------- UI ---------- */
  return (
    <div className="space-y-8">
      {/* Header meta */}
      <div className="text-xs text-gray-500">
        Ref: <span className="font-mono">{refCode || "—"}</span>
      </div>

      {/* =======================
          Search Affiliates
         ======================= */}
      <div className="rounded-md border">
        <div className="px-3 py-2 border-b bg-gray-50">
          <div className="text-sm font-medium">Search Affiliates</div>
        </div>

        <div className="p-3 grid md:grid-cols-5 gap-3">
          <div className="md:col-span-2">
            <label className="block text-xs text-gray-600 mb-1">Search</label>
            <input
              value={filters.q}
              onChange={(e) => setFilters({ ...filters, q: e.target.value })}
              placeholder="Merchant, tag…"
              className="w-full border rounded px-2 py-1 text-sm"
            />
          </div>

          <div>
            <label className="block text-xs text-gray-600 mb-1">Category</label>
            <select
              value={filters.category}
              onChange={(e) => setFilters({ ...filters, category: e.target.value })}
              className="w-full border rounded px-2 py-1 text-sm"
            >
              <option value="all">All</option>
              <option value="electronics">Electronics</option>
              <option value="fashion">Fashion</option>
              <option value="home">Home</option>
              <option value="grocery">Grocery</option>
            </select>
          </div>

          <div>
            <label className="block text-xs text-gray-600 mb-1">Min discount (%)</label>
            <input
              type="number"
              min={0}
              max={90}
              value={filters.discountMin}
              onChange={(e) => setFilters({ ...filters, discountMin: Math.max(0, Math.min(90, Number(e.target.value) || 0)) })}
              className="w-full border rounded px-2 py-1 text-sm"
            />
          </div>

          <div>
            <label className="block text-xs text-gray-600 mb-1">Location</label>
            <input
              value={filters.location}
              onChange={(e) => setFilters({ ...filters, location: e.target.value })}
              placeholder="e.g., Chennai, TN"
              className="w-full border rounded px-2 py-1 text-sm"
            />
          </div>

          <div>
            <label className="block text-xs text-gray-600 mb-1">Availability</label>
            <select
              value={filters.availability}
              onChange={(e) => setFilters({ ...filters, availability: e.target.value as Availability })}
              className="w-full border rounded px-2 py-1 text-sm"
            >
              <option value="all">All</option>
              <option value="open">Open</option>
              <option value="paused">Paused</option>
            </select>
          </div>
        </div>

        <div className="p-3">
          {searching ? (
            <div className="text-sm text-gray-500">Searching…</div>
          ) : merchants.length === 0 ? (
            <div className="text-sm text-gray-500">No merchants match your filters.</div>
          ) : (
            <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-3">
              {merchants.map((m) => (
                <div key={m.id} className="rounded-md border p-3 flex gap-3">
                  <div className="w-12 h-12 rounded bg-gray-200 flex items-center justify-center text-xs">
                    {m.logoUrl ? <img src={m.logoUrl} alt={m.name} className="w-12 h-12 object-cover rounded" /> : m.name[0]}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start gap-2">
                      <div className="font-medium truncate">{m.name}</div>
                      <span className={`ml-auto text-xs px-2 py-0.5 rounded ${
                        m.availability === "open" ? "bg-green-100 text-green-800" : "bg-amber-100 text-amber-800"
                      }`}>
                        {m.availability === "open" ? "Open" : "Paused"}
                      </span>
                    </div>
                    <div className="text-xs text-gray-600">{m.location} • {m.category}</div>
                    <div className="mt-1 flex flex-wrap gap-1">
                      {m.tags.map((t, i) => (
                        <span key={i} className="text-[11px] px-2 py-0.5 rounded bg-gray-100">{t}</span>
                      ))}
                    </div>
                    <div className="mt-2 flex items-center gap-2">
                      <span className="text-sm font-semibold">{m.discountPct}% off</span>
                      <button
                        onClick={() => visitMerchant(m)}
                        className="ml-auto px-3 py-1 rounded border text-sm"
                        disabled={m.availability !== "open"}
                        title={m.availability !== "open" ? "Currently paused" : "Open merchant"}
                      >
                        Get link / Visit
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* =======================
          My Affiliate Activity
         ======================= */}
      <div className="rounded-md border">
        <div className="px-3 py-2 border-b bg-gray-50 flex flex-wrap items-center gap-3">
          <div className="text-sm font-medium">My Affiliate Activity</div>

          <div className="ml-auto flex items-center gap-2">
            {(["me","l1","l2","l3","downline"] as Scope[]).map(s => (
              <button
                key={s}
                onClick={() => setScope(s)}
                className={`px-3 py-1 rounded-full border text-sm ${
                  scope === s ? "bg-blue-600 text-white border-blue-600" : "bg-white"
                }`}
              >
                {s === "me" ? "Me" : s.toUpperCase()}
              </button>
            ))}
          </div>
        </div>

        {/* KPIs */}
        <div className="p-3 grid sm:grid-cols-2 lg:grid-cols-4 gap-3">
          <KPI title="Clicks" value={totalClicks.toLocaleString("en-IN")} />
          <KPI title="Carts" value={totalCarts.toLocaleString("en-IN")} />
          <KPI title="Purchases (#)" value={totalPurchases.toLocaleString("en-IN")} />
          <KPI title="Purchases (₹)" value={formatINR(totalValue)} />
        </div>

        {/* Filters + Export */}
        <div className="px-3 pb-3 flex flex-wrap items-center gap-3">
          <div className="flex items-center gap-2">
            <span className="text-sm text-gray-700">From</span>
            <input
              type="date"
              value={from}
              onChange={(e) => setFrom(e.target.value)}
              className="border rounded px-2 py-1 text-sm"
            />
          </div>
          <div className="flex items-center gap-2">
            <span className="text-sm text-gray-700">To</span>
            <input
              type="date"
              value={to}
              onChange={(e) => setTo(e.target.value)}
              className="border rounded px-2 py-1 text-sm"
            />
          </div>

          <div className="ml-auto flex items-center gap-2">
            <button
              onClick={() => {
                const csv = [
                  ["date","scope","clicks","carts","purchasesCount","purchasesValue"].join(","),
                  ...rows.map(r => [r.date, r.scope, r.clicks, r.carts, r.purchasesCount, r.purchasesValue].join(",")),
                ].join("\n");
                const blob = new Blob([csv], { type: "text/csv;charset=utf-8" });
                const url = URL.createObjectURL(blob);
                const a = document.createElement("a");
                a.href = url;
                a.download = `affiliate_activity_${from}_${to}.csv`;
                a.click();
                URL.revokeObjectURL(url);
              }}
              className="px-3 py-1 rounded border text-sm"
              disabled={!rows.length}
            >
              Download CSV
            </button>
          </div>
        </div>

        {/* Table */}
        <div className="px-3 pb-3 overflow-x-auto">
          {loadingActivity ? (
            <div className="text-sm text-gray-500">Loading…</div>
          ) : rows.length === 0 ? (
            <div className="text-sm text-gray-500">No data for selected window.</div>
          ) : (
            <table className="min-w-full text-sm">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-3 py-2 text-left">Date</th>
                  <th className="px-3 py-2 text-right">Clicks</th>
                  <th className="px-3 py-2 text-right">Carts</th>
                  <th className="px-3 py-2 text-right">Purchases (#)</th>
                  <th className="px-3 py-2 text-right">Purchases (₹)</th>
                </tr>
              </thead>
              <tbody className="divide-y">
                {rows.map((r, i) => (
                  <tr key={`${r.date}-${i}`}>
                    <td className="px-3 py-2">{new Date(r.date).toLocaleDateString()}</td>
                    <td className="px-3 py-2 text-right">{r.clicks.toLocaleString("en-IN")}</td>
                    <td className="px-3 py-2 text-right">{r.carts.toLocaleString("en-IN")}</td>
                    <td className="px-3 py-2 text-right">{r.purchasesCount.toLocaleString("en-IN")}</td>
                    <td className="px-3 py-2 text-right">{formatINR(r.purchasesValue)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

        {/* Top merchants */}
        <div className="px-3 pb-4">
          <div className="text-sm font-medium mb-2">Top merchants (downline)</div>
          {top.length === 0 ? (
            <div className="text-sm text-gray-500">No merchant data.</div>
          ) : (
            <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-3">
              {top.map((t) => (
                <div key={t.merchantId} className="rounded-md border p-3">
                  <div className="font-medium">{t.merchantName}</div>
                  <div className="text-xs text-gray-600">Orders: {t.purchasesCount.toLocaleString("en-IN")}</div>
                  <div className="text-xs text-gray-600">Value: {formatINR(t.purchasesValue)}</div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

/* Sub */
function KPI({ title, value }: { title: string; value: string }) {
  return (
    <div className="rounded-md border px-3 py-3">
      <div className="text-xs text-gray-500">{title}</div>
      <div className="text-2xl font-bold">{value}</div>
    </div>
  );
}
