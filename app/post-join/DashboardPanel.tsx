"use client";

import React, { useEffect, useMemo, useState } from "react";
import { supabase } from "@/lib/supabase-browser";

/* ============================
   Types (mirror future APIs)
============================ */
type WindowKey = "yesterday" | "last7" | "prev7" | "last30" | "uptoLastMonth";
type WhoScope = "me" | "l1" | "l2" | "l3" | "downline" | "custom";
type WhatMetric =
  | "points_earned"
  | "points_redeemed"
  | "purchases_value"
  | "transactions"
  | "avg_order_value";
type EntityForExport = "points" | "purchases" | "redemptions";

type SummaryCard = {
  label: string;
  value: number;
  deltaPct?: number; // vs previous comparable window
};

type Row = {
  date: string;          // ISO date (YYYY-MM-DD is fine)
  who: string;           // e.g., Me / L1 / L2 / ...
  points_earned: number;
  points_redeemed: number;
  purchases_value: number; // rupees
  transactions: number;
  avg_order_value: number; // rupees
};

/* ============================
   Tiny client-side cache
   - per language + ref + scope + metric + range + depth
============================ */
type CacheVal<T> = { ts: number; data: T };
const _cache = new Map<string, CacheVal<any>>();
const DEFAULT_TTL_MS = 90_000;

function langKey() {
  // keep it simple; page language affects “per-language” cache grouping
  if (typeof navigator !== "undefined" && navigator.language) return navigator.language.toLowerCase();
  return "en";
}

async function withCache<T>(key: string, loader: () => Promise<T>, ttlMs = DEFAULT_TTL_MS): Promise<T> {
  const hit = _cache.get(key);
  const now = Date.now();
  if (hit && now - hit.ts < ttlMs) return hit.data as T;
  const data = await loader();
  _cache.set(key, { ts: now, data });
  return data;
}

/* ============================
   RPC-backed data fetchers
   RPCs available:
   - public.dashboard_windows()
   - public.rpc_dashboard_daily_rows(p_scope text, p_ref text, p_from date, p_to date, p_custom_depth int)
============================ */
type WindowRow = { win: WindowKey; from_date: string; to_date: string; label: string; ord: number };

async function fetchWindowsCached(): Promise<WindowRow[]> {
  const key = `${langKey()}::windows`;
  return withCache(key, async () => {
    const { data, error } = await supabase.rpc("dashboard_windows", {});
    if (error) throw error;
    return (data ?? []).map((r: any) => ({
      win: r.win as WindowKey,
      from_date: r.from_date,
      to_date: r.to_date,
      label: r.label,
      ord: r.ord,
    }));
  });
}

type MetricKey = "points_earned" | "points_redeemed" | "purchases_value";

async function sumMetricForRange(params: {
  scope: WhoScope;
  ref: string;
  what: MetricKey;
  fromISO: string; // YYYY-MM-DD
  toISO: string;   // YYYY-MM-DD
  customDepth?: number;
}): Promise<number> {
  const { scope, ref, what, fromISO, toISO, customDepth } = params;
  const k = `${langKey()}::sum::${ref || "-"}::${scope}::${what}::${fromISO}..${toISO}::${customDepth ?? "na"}`;
  return withCache(k, async () => {
    const { data, error } = await supabase.rpc("rpc_dashboard_daily_rows", {
      p_scope: scope,
      p_ref: ref || null,
      p_from: fromISO,
      p_to: toISO,
      p_custom_depth: customDepth ?? null,
    });
    if (error) throw error;
    const rows = (data ?? []) as any[];
    return rows.reduce((acc, r) => acc + Number(r[what] ?? 0), 0);
  });
}

function fmtDate(d: string) {
  // Ensure YYYY-MM-DD (RPC accepts date)
  return new Date(d).toISOString().slice(0, 10);
}

async function buildSummaryForMetric(params: {
  scope: WhoScope;
  ref: string;
  metric: MetricKey;
  customDepth?: number;
}): Promise<Record<WindowKey, { label: string; value: number; deltaPct?: number }>> {
  const { scope, ref, metric, customDepth } = params;
  const wins = await fetchWindowsCached();

  const deltaPair = (w: WindowKey, from: string, to: string):
    | { prevFrom: string; prevTo: string }
    | null => {
    const f = new Date(from);
    const t = new Date(to);
    const days = Math.round((+t - +f) / 86400000) + 1;

    if (w === "yesterday") {
      const pf = new Date(f); pf.setDate(pf.getDate() - 1);
      const d = fmtDate(pf.toISOString());
      return { prevFrom: d, prevTo: d };
    }
    if (w === "last7") {
      const prev = wins.find((x) => x.win === "prev7");
      return prev ? { prevFrom: fmtDate(prev.from_date), prevTo: fmtDate(prev.to_date) } : null;
    }
    if (w === "last30") {
      const pf = new Date(f); pf.setDate(pf.getDate() - days);
      const pt = new Date(f); pt.setDate(pt.getDate() - 1);
      return { prevFrom: fmtDate(pf.toISOString()), prevTo: fmtDate(pt.toISOString()) };
    }
    if (w === "uptoLastMonth") {
      const first = new Date(from); first.setDate(1);
      const prevMonthEnd = new Date(first.getTime() - 86400000);
      const prevMonthFirst = new Date(prevMonthEnd.getFullYear(), prevMonthEnd.getMonth(), 1);
      return { prevFrom: fmtDate(prevMonthFirst.toISOString()), prevTo: fmtDate(prevMonthEnd.toISOString()) };
    }
    return null; // prev7 no delta by default
  };

  const out: Record<WindowKey, { label: string; value: number; deltaPct?: number }> = {} as any;

  for (const w of wins) {
    const fromISO = fmtDate(w.from_date);
    const toISO = fmtDate(w.to_date);
    const value = await sumMetricForRange({
      scope,
      ref,
      what: metric,
      fromISO,
      toISO,
      customDepth,
    });

    let deltaPct: number | undefined = undefined;
    const d = deltaPair(w.win, fromISO, toISO);
    if (d) {
      const prevVal = await sumMetricForRange({
        scope,
        ref,
        what: metric,
        fromISO: d.prevFrom,
        toISO: d.prevTo,
        customDepth,
      });
      if (prevVal > 0) {
        deltaPct = Math.round(((value - prevVal) / prevVal) * 100);
      } else if (value > 0) {
        deltaPct = 100;
      } else {
        deltaPct = 0;
      }
    }

    out[w.win as WindowKey] = { label: w.label, value, deltaPct };
  }

  return out;
}

// Public wrappers expected by your component
async function api_points_summary(params: { scope: WhoScope; ref: string; customDepth?: number }) {
  return buildSummaryForMetric({ scope: params.scope, ref: params.ref, metric: "points_earned", customDepth: params.customDepth });
}
async function api_purchases_summary(params: { scope: WhoScope; ref: string; customDepth?: number }) {
  return buildSummaryForMetric({ scope: params.scope, ref: params.ref, metric: "purchases_value", customDepth: params.customDepth });
}
async function api_redemptions_summary(params: { scope: WhoScope; ref: string; customDepth?: number }) {
  return buildSummaryForMetric({ scope: params.scope, ref: params.ref, metric: "points_redeemed", customDepth: params.customDepth });
}

// Explorer/Table rows via RPC (also cached)
async function api_analytics_rows(params: {
  scope: WhoScope;
  ref: string;
  what: WhatMetric;
  from: string; // ISO
  to: string;   // ISO
  customDepth?: number;
}): Promise<Row[]> {
  const { scope, ref, from, to, customDepth, what } = params;
  const fromD = from.slice(0, 10);
  const toD = to.slice(0, 10);
  const k = `${langKey()}::rows::${ref || "-"}::${scope}::${fromD}..${toD}::${customDepth ?? "na"}`;
  return withCache(k, async () => {
    const { data, error } = await supabase.rpc("rpc_dashboard_daily_rows", {
      p_scope: scope,
      p_ref: ref || null,
      p_from: fromD,
      p_to: toD,
      p_custom_depth: customDepth ?? null,
    });
    if (error) throw error;

    const rows = (data ?? []).map((r: any) => ({
      date: r.date, // already YYYY-MM-DD
      who: String(r.who || "").toUpperCase(),
      points_earned: Number(r.points_earned ?? 0),
      points_redeemed: Number(r.points_redeemed ?? 0),
      purchases_value: Number(r.purchases_value ?? 0),
      transactions: Number(r.transactions ?? 0),
      avg_order_value: Number(r.avg_order_value ?? 0),
    })) as Row[];

    // Note: we don’t filter by `what` for caching. The grid displays all columns.
    return rows;
  });
}

/* ============================
   Helpers (unchanged)
============================ */
function daysBackISO(d: number) {
  const x = new Date(Date.now() - d * 86400000);
  x.setHours(0, 0, 0, 0);
  return x.toISOString();
}

function formatINR(n: number) {
  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    maximumFractionDigits: 0,
  }).format(n);
}

function downloadCSV(filename: string, rows: Row[]) {
  const headers = [
    "date",
    "who",
    "points_earned",
    "points_redeemed",
    "purchases_value",
    "transactions",
    "avg_order_value",
  ];
  const lines = [headers.join(",")].concat(
    rows.map((r) =>
      [
        r.date,
        `"${r.who}"`,
        r.points_earned,
        r.points_redeemed,
        r.purchases_value,
        r.transactions,
        r.avg_order_value,
      ].join(",")
    )
  );
  const blob = new Blob([lines.join("\n")], { type: "text/csv;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

function windowToRange(w: WindowKey): { fromISO: string; toISO: string } {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const to = new Date(today);
  const from = new Date(today);
  if (w === "yesterday") {
    from.setDate(from.getDate() - 1);
    to.setDate(to.getDate() - 1);
  } else if (w === "last7") {
    from.setDate(from.getDate() - 6);
  } else if (w === "prev7") {
    to.setDate(to.getDate() - 7);
    from.setDate(from.getDate() - 13);
  } else if (w === "last30") {
    from.setDate(from.getDate() - 29);
  } else if (w === "uptoLastMonth") {
    const firstOfThis = new Date(today.getFullYear(), today.getMonth(), 1);
    const lastOfPrev = new Date(firstOfThis.getTime() - 86400000);
    const firstOfPrev = new Date(lastOfPrev.getFullYear(), lastOfPrev.getMonth(), 1);
    from.setTime(firstOfPrev.getTime());
    to.setTime(lastOfPrev.getTime());
  }
  return { fromISO: from.toISOString(), toISO: to.toISOString() };
}

/* ============================
   Component
============================ */
export default function DashboardPanel({ refCode }: { refCode: string }) {
  /* Cards state */
  const [scope, setScope] = useState<WhoScope>("me");
  const [cardsPoints, setCardsPoints] = useState<Record<WindowKey, SummaryCard> | null>(null);
  const [cardsPurch, setCardsPurch] = useState<Record<WindowKey, SummaryCard> | null>(null);
  const [cardsRedeem, setCardsRedeem] = useState<Record<WindowKey, SummaryCard> | null>(null);

  /* Explorer state */
  const [what, setWhat] = useState<WhatMetric>("purchases_value");
  const [from, setFrom] = useState<string>(() => daysBackISO(29).slice(0, 10)); // yyyy-mm-dd
  const [to, setTo] = useState<string>(() => daysBackISO(0).slice(0, 10));
  const [customDepth, setCustomDepth] = useState<number>(2);
  const [rows, setRows] = useState<Row[]>([]);
  const [loadingRows, setLoadingRows] = useState(false);

  /* Details drawer state */
  const [detailOpen, setDetailOpen] = useState(false);
  const [detailTitle, setDetailTitle] = useState<string>("");
  const [detailRows, setDetailRows] = useState<Row[]>([]);
  const [detailLoading, setDetailLoading] = useState(false);

  /* Load cards when scope/ref changes */
  useEffect(() => {
    let alive = true;
    (async () => {
      const [p, pv, r] = await Promise.all([
        api_points_summary({ scope, ref: refCode }),
        api_purchases_summary({ scope, ref: refCode }),
        api_redemptions_summary({ scope, ref: refCode }),
      ]);
      if (!alive) return;
      setCardsPoints(p);
      setCardsPurch(pv);
      setCardsRedeem(r);
    })().catch(console.error);
    return () => {
      alive = false;
    };
  }, [scope, refCode]);

  /* Load explorer table */
  useEffect(() => {
    let alive = true;
    (async () => {
      setLoadingRows(true);
      try {
        const data = await api_analytics_rows({
          scope,
          ref: refCode,
          what,
          from: new Date(from).toISOString(),
          to: new Date(to).toISOString(),
          customDepth,
        });
        if (alive) setRows(data);
      } finally {
        if (alive) setLoadingRows(false);
      }
    })().catch(console.error);
    return () => {
      alive = false;
    };
  }, [scope, what, from, to, customDepth, refCode]);

  const winOrder: WindowKey[] = ["yesterday", "last7", "prev7", "last30", "uptoLastMonth"];
  const label = (w: WindowKey) =>
    ({ yesterday: "Yesterday", last7: "Last 7d", prev7: "Previous 7d", last30: "Last 30d", uptoLastMonth: "Up-to-Last-Month" }[w]);

  async function openDetails(metric: WhatMetric, w: WindowKey, title: string) {
    setDetailTitle(`${title} — ${label(w)}`);
    setDetailOpen(true);
    setDetailLoading(true);
    try {
      const { fromISO, toISO } = windowToRange(w);
      const data = await api_analytics_rows({
        scope,
        ref: refCode,
        what: metric,
        from: fromISO,
        to: toISO,
        customDepth,
      });
      setDetailRows(data);
    } finally {
      setDetailLoading(false);
    }
  }

  return (
    <div className="max-w-6xl mx-auto space-y-6">
      {/* Scope picker */}
      <div className="flex flex-wrap items-center gap-2">
        <span className="text-sm text-gray-600">Scope:</span>
        {(["me", "l1", "l2", "l3", "downline", "custom"] as WhoScope[]).map((s) => (
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
        {scope === "custom" && (
          <div className="flex items-center gap-2 ml-2">
            <span className="text-sm text-gray-600">Depth ≤</span>
            <input
              type="number"
              min={1}
              max={10}
              value={customDepth}
              onChange={(e) => setCustomDepth(Math.max(1, Math.min(10, Number(e.target.value) || 1)))}
              className="w-16 border rounded px-2 py-1 text-sm"
            />
          </div>
        )}
        <div className="ml-auto text-xs text-gray-500">
          Ref: <span className="font-mono">{refCode || "—"}</span>
        </div>
      </div>

      {/* Cards: Points earned (clickable) */}
      <CardGroup
        title="Points earned"
        data={cardsPoints}
        format={(n) => n.toLocaleString("en-IN")}
        order={winOrder}
        label={label}
        onCardClick={(w) => openDetails("points_earned", w, "Points earned")}
      />

      {/* Cards: Points redeemed (clickable) */}
      <CardGroup
        title="Points redeemed"
        data={cardsRedeem}
        format={(n) => n.toLocaleString("en-IN")}
        order={winOrder}
        label={label}
        onCardClick={(w) => openDetails("points_redeemed", w, "Points redeemed")}
      />

      {/* Cards: Purchases (₹) (clickable) */}
      <CardGroup
        title="Purchases (₹)"
        data={cardsPurch}
        format={formatINR}
        order={winOrder}
        label={label}
        onCardClick={(w) => openDetails("purchases_value", w, "Purchases (₹)")}
      />

      {/* Explorer */}
      <div className="rounded-md border">
        <div className="px-3 py-2 border-b bg-gray-50 flex flex-wrap items-center gap-3">
          <div className="flex items-center gap-2">
            <span className="text-sm text-gray-700">What:</span>
            <select
              value={what}
              onChange={(e) => setWhat(e.target.value as WhatMetric)}
              className="border rounded px-2 py-1 text-sm"
            >
              <option value="points_earned">Points (earned)</option>
              <option value="points_redeemed">Points (redeemed)</option>
              <option value="purchases_value">Purchases (₹)</option>
              <option value="transactions">#Transactions</option>
              <option value="avg_order_value">Average order value (₹)</option>
            </select>
          </div>

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
              onClick={() => downloadCSV(`analytics_${what}_${from}_${to}.csv`, rows)}
              className="px-3 py-1 rounded border text-sm"
              disabled={!rows.length}
            >
              Download CSV
            </button>
          </div>
        </div>

        <div className="p-3 overflow-x-auto">
          {loadingRows ? (
            <div className="text-sm text-gray-500">Loading…</div>
          ) : rows.length === 0 ? (
            <div className="text-sm text-gray-500">No data for selected window.</div>
          ) : (
            <table className="min-w-full text-sm">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-3 py-2 text-left">Date</th>
                  <th className="px-3 py-2 text-left">Who</th>
                  <th className="px-3 py-2 text-right">Points (earned)</th>
                  <th className="px-3 py-2 text-right">Points (redeemed)</th>
                  <th className="px-3 py-2 text-right">Purchases (₹)</th>
                  <th className="px-3 py-2 text-right">#Tx</th>
                  <th className="px-3 py-2 text-right">Avg order (₹)</th>
                </tr>
              </thead>
              <tbody className="divide-y">
                {rows.map((r, i) => (
                  <tr key={`${r.date}-${i}`}>
                    <td className="px-3 py-2">{new Date(r.date).toLocaleDateString()}</td>
                    <td className="px-3 py-2">{r.who}</td>
                    <td className="px-3 py-2 text-right">{r.points_earned.toLocaleString("en-IN")}</td>
                    <td className="px-3 py-2 text-right">{r.points_redeemed.toLocaleString("en-IN")}</td>
                    <td className="px-3 py-2 text-right">{formatINR(r.purchases_value)}</td>
                    <td className="px-3 py-2 text-right">{r.transactions}</td>
                    <td className="px-3 py-2 text-right">{formatINR(r.avg_order_value)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* Drawer: Details */}
      {detailOpen && (
        <div className="fixed inset-0 z-30">
          <div className="absolute inset-0 bg-black/30" onClick={() => setDetailOpen(false)} />
          <div className="absolute right-0 top-0 h-full w-full max-w-2xl bg-white shadow-2xl flex flex-col">
            <div className="px-4 py-3 border-b flex items-center gap-3">
              <div className="text-lg font-semibold">{detailTitle}</div>
              <button className="ml-auto px-3 py-1 rounded border" onClick={() => setDetailOpen(false)}>
                Close
              </button>
            </div>
            <div className="p-3 overflow-auto flex-1">
              {detailLoading ? (
                <div className="text-sm text-gray-500">Loading…</div>
              ) : detailRows.length === 0 ? (
                <div className="text-sm text-gray-500">No records.</div>
              ) : (
                <table className="min-w-full text-sm">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-3 py-2 text-left">Date</th>
                      <th className="px-3 py-2 text-left">Who</th>
                      <th className="px-3 py-2 text-right">Points (earned)</th>
                      <th className="px-3 py-2 text-right">Points (redeemed)</th>
                      <th className="px-3 py-2 text-right">Purchases (₹)</th>
                      <th className="px-3 py-2 text-right">#Tx</th>
                      <th className="px-3 py-2 text-right">Avg order (₹)</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y">
                    {detailRows.map((r, i) => (
                      <tr key={`${r.date}-${i}`}>
                        <td className="px-3 py-2">{new Date(r.date).toLocaleDateString()}</td>
                        <td className="px-3 py-2">{r.who}</td>
                        <td className="px-3 py-2 text-right">{r.points_earned.toLocaleString("en-IN")}</td>
                        <td className="px-3 py-2 text-right">{r.points_redeemed.toLocaleString("en-IN")}</td>
                        <td className="px-3 py-2 text-right">{formatINR(r.purchases_value)}</td>
                        <td className="px-3 py-2 text-right">{r.transactions}</td>
                        <td className="px-3 py-2 text-right">{formatINR(r.avg_order_value)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

/* ============================
   Sub-components
============================ */
function CardGroup({
  title,
  data,
  format,
  order,
  label,
  onCardClick,
}: {
  title: string;
  data: Record<WindowKey, SummaryCard> | null;
  format: (n: number) => string;
  order: WindowKey[];
  label: (w: WindowKey) => string;
  onCardClick?: (w: WindowKey) => void;
}) {
  return (
    <div className="space-y-2">
      <div className="text-lg font-semibold">{title}</div>
      <div className="grid sm:grid-cols-2 lg:grid-cols-5 gap-3">
        {data
          ? order.map((k) => {
              const c = data[k];
              const up = (c.deltaPct ?? 0) >= 0;
              const body = (
                <>
                  <div className="text-xs text-gray-500 flex items-center justify-between">
                    <span>{label(k)}</span>
                    <span className="text-[10px] text-gray-400 underline">Details</span>
                  </div>
                  <div className="text-2xl font-bold">
                    {title.includes("₹") ? format(c.value) : c.value.toLocaleString("en-IN")}
                  </div>
                  {"deltaPct" in c && (
                    <div className={`text-xs ${up ? "text-green-700" : "text-red-700"}`}>
                      {up ? "▲" : "▼"} {Math.abs(c.deltaPct || 0)}%
                    </div>
                  )}
                </>
              );

              return onCardClick ? (
                <button
                  key={k}
                  onClick={() => onCardClick(k)}
                  className="rounded-md border px-3 py-3 text-left hover:bg-gray-50 transition cursor-pointer"
                  title={`View details for ${label(k)}`}
                >
                  {body}
                </button>
              ) : (
                <div key={k} className="rounded-md border px-3 py-3">
                  {body}
                </div>
              );
            })
          : <div className="text-sm text-gray-500">Loading…</div>}
      </div>
    </div>
  );
}
