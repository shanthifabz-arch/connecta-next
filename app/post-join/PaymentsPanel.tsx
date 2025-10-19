"use client";

import React, { useEffect, useMemo, useState } from "react";
import { supabase } from "@/lib/supabase-browser";

/* ============================
   Types (mirror RPC payloads)
============================ */
type WindowKey = "yesterday" | "last7" | "last30" | "uptoLastMonth";
type Scope = "me" | "l1" | "l2" | "l3" | "downline";

type EarningsBucket = {
  pending: number;                 // ₹
  settled: number;                 // ₹
  expected_settlement?: string;    // ISO date
};
type EarningsSummary = Record<WindowKey, EarningsBucket>;

type TxStatus = "pending" | "processed" | "failed";
type TxType = "commission" | "redemption" | "fee";
type SourceLevel = "self" | "l1" | "l2" | "l3" | "downline";

type TransactionRow = {
  id: string;
  date: string;        // ISO
  type: TxType;
  source: SourceLevel;
  amount_inr: number;  // ₹
  status: TxStatus;
  ref: string;
};

type ProductItem = {
  id: string;
  name: string;
  merchant: string;
  discount_pct: number;
  category: string;
  location?: string | null;
};

/* ============================
   Tiny cache (per-ref/params)
============================ */
type CacheEntry<T> = { value: T; expiresAt: number };
const _cache = new Map<string, CacheEntry<any>>();
const TTL_MS = 30_000;

function getCache<T>(key: string): T | null {
  const it = _cache.get(key);
  if (!it) return null;
  if (Date.now() > it.expiresAt) {
    _cache.delete(key);
    return null;
  }
  return it.value as T;
}
function setCache<T>(key: string, value: T) {
  _cache.set(key, { value, expiresAt: Date.now() + TTL_MS });
}
function k(parts: any[]) {
  return parts.map((p) => (p ?? "")).join("|");
}

/* ============================
   Helpers
============================ */
function formatINR(n: number) {
  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    maximumFractionDigits: 0,
  }).format(n);
}
function fmtLabel(w: WindowKey) {
  return {
    yesterday: "Yesterday",
    last7: "Last 7 days",
    last30: "Last 30 days",
    uptoLastMonth: "Up-to-Last-Month",
  }[w];
}
function toISODate(d: string | Date) {
  const x = new Date(d);
  x.setHours(0, 0, 0, 0);
  return x.toISOString();
}
function toYMD(d: string | Date) {
  return toISODate(d).slice(0, 10);
}

/* ============================
   RPC-backed API functions
============================ */
async function api_payments_earnings(params: {
  refCode: string;
  scope: Scope;
  from?: string; // yyyy-mm-dd
  to?: string;   // yyyy-mm-dd
}): Promise<EarningsSummary> {
  const p_from = params.from ?? null;
  const p_to = params.to ?? null;

  const key = k(["earn", params.refCode, params.scope, p_from, p_to]);
  const cached = getCache<EarningsSummary>(key);
  if (cached) return cached;

  const { data, error } = await supabase.rpc("rpc_payments_earnings", {
    p_ref: params.refCode,
    p_scope: params.scope,
    p_from,
    p_to,
  });

  if (error) throw error;

  // data: rows with win, from_date, to_date, pending, settled, expected_settlement
  const empty: EarningsSummary = {
    yesterday: { pending: 0, settled: 0 },
    last7: { pending: 0, settled: 0 },
    last30: { pending: 0, settled: 0 },
    uptoLastMonth: { pending: 0, settled: 0 },
  };

  const out = { ...empty };
  (data ?? []).forEach((r: any) => {
    const win = (r.win as string) as WindowKey;
    if (!out[win]) return;
    out[win] = {
      pending: Number(r.pending || 0),
      settled: Number(r.settled || 0),
      expected_settlement: r.expected_settlement
        ? new Date(r.expected_settlement).toISOString()
        : undefined,
    };
  });

  setCache(key, out);
  return out;
}

// transactions + exact count (two RPCs)
async function api_payments_transactions(params: {
  refCode: string;
  scope: Scope;
  from: string; // yyyy-mm-dd
  to: string;   // yyyy-mm-dd
  status?: TxStatus | "all";
  level?: SourceLevel | "all";
  page?: number;
  pageSize?: number;
  refQuery?: string;
}): Promise<{ rows: TransactionRow[]; total: number }> {
  const p_status = params.status ?? "all";
  const p_level = params.level ?? "all";
  const p_page = params.page ?? 1;
  const p_page_size = params.pageSize ?? 25;
  const p_query = params.refQuery ?? null;

  // Cache key ignores page for the count RPC (but includes filters)
  const keyRows = k([
    "txRows", params.refCode, params.scope, params.from, params.to,
    p_status, p_level, p_page, p_page_size, p_query
  ]);
  const keyCount = k([
    "txCount", params.refCode, params.scope, params.from, params.to,
    p_status, p_level, p_query
  ]);

  const cachedRows = getCache<TransactionRow[]>(keyRows);
  const cachedCount = getCache<number>(keyCount);
  if (cachedRows && typeof cachedCount === "number") {
    return { rows: cachedRows, total: cachedCount };
  }

  const [rowsRes, countRes] = await Promise.all([
    supabase.rpc("rpc_payments_transactions", {
      p_ref: params.refCode,
      p_scope: params.scope,
      p_from: params.from,
      p_to: params.to,
      p_status,
      p_level,
      p_page,
      p_page_size,
      p_ref_query: p_query,
    }),
    supabase.rpc("rpc_payments_transactions_count", {
      p_ref: params.refCode,
      p_scope: params.scope,
      p_from: params.from,
      p_to: params.to,
      p_status,
      p_level,
      p_ref_query: p_query,
    }),
  ]);

  if (rowsRes.error) throw rowsRes.error;
  if (countRes.error) throw countRes.error;

  const rows: TransactionRow[] = (rowsRes.data ?? []).map((r: any) => ({
    id: String(r.id),
    date: new Date(r.date).toISOString(),
    type: (r.type || "fee") as TxType,
    source: (r.source || "downline") as SourceLevel,
    amount_inr: Number(r.amount_inr || 0),
    status: (r.status || "pending") as TxStatus,
    ref: String(r.ref || r.id),
  }));

  const total = Number(countRes.data ?? 0);

  setCache(keyRows, rows);
  setCache(keyCount, total);

  return { rows, total };
}

/* ============================
   Products search (stub for now)
============================ */
async function api_products_search(params: {
  ownerScope: "downline";
  q?: string;
}): Promise<ProductItem[]> {
  const all: ProductItem[] = [
    { id: "p1", name: "Organic Honey 500g", merchant: "GreenFarm L1", discount_pct: 10, category: "Grocery", location: "Chennai" },
    { id: "p2", name: "Cotton T-shirt", merchant: "WearWell L2", discount_pct: 15, category: "Apparel", location: "Madurai" },
    { id: "p3", name: "Handmade Soap", merchant: "CareCraft L3", discount_pct: 8, category: "Personal Care", location: "Coimbatore" },
  ];
  if (!params.q) return all;
  const q = params.q.toLowerCase();
  return all.filter(
    (p) =>
      p.name.toLowerCase().includes(q) ||
      p.merchant.toLowerCase().includes(q) ||
      p.category.toLowerCase().includes(q)
  );
}

/* ============================
   Component
============================ */
export default function PaymentsPanel({ refCode }: { refCode: string }) {
  // Scope & date window for both sections
  const [scope, setScope] = useState<Scope>("me");
  const [from, setFrom] = useState(() => toYMD(new Date(Date.now() - 29 * 86400000)));
  const [to, setTo] = useState(() => toYMD(new Date()));

  // Earnings timeline
  const [earnings, setEarnings] = useState<EarningsSummary | null>(null);

  // Transactions
  const [status, setStatus] = useState<TxStatus | "all">("all");
  const [level, setLevel] = useState<SourceLevel | "all">("all");
  const [amtMin, setAmtMin] = useState<string>("");
  const [amtMax, setAmtMax] = useState<string>("");
  const [refQuery, setRefQuery] = useState<string>("");
  const [txRows, setTxRows] = useState<TransactionRow[]>([]);
  const [txTotal, setTxTotal] = useState<number>(0);
  const [txPage, setTxPage] = useState<number>(1);
  const [loadingTx, setLoadingTx] = useState(false);

  // Products search
  const [pQuery, setPQuery] = useState("");
  const [pResults, setPResults] = useState<ProductItem[]>([]);
  const [pLoading, setPLoading] = useState(false);

  // Load earnings summary
  useEffect(() => {
    let alive = true;
    (async () => {
      try {
        const data = await api_payments_earnings({
          refCode,
          scope,
          from,
          to,
        });
        if (alive) setEarnings(data);
      } catch (e) {
        console.error("rpc_payments_earnings failed", e);
        if (alive) setEarnings(null);
      }
    })();
    return () => {
      alive = false;
    };
  }, [refCode, scope, from, to]);

  // Load transactions with filters (server filters + client amount range)
  useEffect(() => {
    let alive = true;
    (async () => {
      setLoadingTx(true);
      try {
        const { rows, total } = await api_payments_transactions({
          refCode,
          scope,
          from,
          to,
          status,
          level,
          page: txPage,
          pageSize: 25,
          refQuery,
        });

        const min = amtMin ? Number(amtMin) : -Infinity;
        const max = amtMax ? Number(amtMax) : +Infinity;
        const final = rows.filter((r) => r.amount_inr >= min && r.amount_inr <= max);

        if (alive) {
          setTxRows(final);
          setTxTotal(total);
        }
      } catch (e) {
        console.error("rpc_payments_transactions failed", e);
        if (alive) {
          setTxRows([]);
          setTxTotal(0);
        }
      } finally {
        if (alive) setLoadingTx(false);
      }
    })();
    return () => {
      alive = false;
    };
  }, [refCode, scope, from, to, status, level, txPage, refQuery, amtMin, amtMax]);

  // Products search
  async function runProductSearch() {
    setPLoading(true);
    try {
      const data = await api_products_search({ ownerScope: "downline", q: pQuery });
      setPResults(data);
    } finally {
      setPLoading(false);
    }
  }

  const windows: WindowKey[] = ["yesterday", "last7", "last30", "uptoLastMonth"];

  return (
    <div className="max-w-6xl mx-auto space-y-8">
      {/* Scope row */}
      <div className="flex flex-wrap items-center gap-2">
        <span className="text-sm text-gray-600">Scope:</span>
        {(["me", "l1", "l2", "l3", "downline"] as Scope[]).map((s) => (
          <button
            key={s}
            onClick={() => { setScope(s); setTxPage(1); }}
            className={`px-3 py-1 rounded-full border text-sm ${
              scope === s ? "bg-blue-600 text-white border-blue-600" : "bg-white"
            }`}
          >
            {s === "me" ? "Me" : s.toUpperCase()}
          </button>
        ))}
        <div className="ml-auto text-xs text-gray-500">
          Ref: <span className="font-mono">{refCode || "—"}</span>
        </div>
      </div>

      {/* Earnings Timeline */}
      <section className="space-y-2">
        <div className="flex flex-wrap items-center gap-3">
          <div className="text-lg font-semibold">Earnings Timeline</div>
          <div className="ml-auto flex items-center gap-2">
            <span className="text-sm text-gray-700">From</span>
            <input
              type="date"
              value={from}
              onChange={(e) => { setFrom(e.target.value); setTxPage(1); }}
              className="border rounded px-2 py-1 text-sm"
            />
            <span className="text-sm text-gray-700">To</span>
            <input
              type="date"
              value={to}
              onChange={(e) => { setTo(e.target.value); setTxPage(1); }}
              className="border rounded px-2 py-1 text-sm"
            />
          </div>
        </div>

        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-3">
          {earnings ? (
            windows.map((w) => {
              const b = earnings[w];
              const total = (b?.pending ?? 0) + (b?.settled ?? 0);
              return (
                <div key={w} className="rounded-md border px-3 py-3">
                  <div className="text-xs text-gray-500">{fmtLabel(w)}</div>
                  <div className="text-2xl font-bold">{formatINR(total)}</div>
                  <div className="mt-1 flex flex-wrap gap-2 text-xs">
                    <span className="px-2 py-0.5 rounded bg-amber-100 text-amber-800">
                      Pending: {formatINR(b?.pending ?? 0)}
                    </span>
                    <span className="px-2 py-0.5 rounded bg-green-100 text-green-800">
                      Settled: {formatINR(b?.settled ?? 0)}
                    </span>
                    {b?.expected_settlement && (
                      <span className="px-2 py-0.5 rounded bg-gray-100 text-gray-700">
                        Next: {new Date(b.expected_settlement).toLocaleDateString()}
                      </span>
                    )}
                  </div>
                </div>
              );
            })
          ) : (
            <div className="text-sm text-gray-500">Loading timeline…</div>
          )}
        </div>
      </section>

      {/* Transactions Table */}
      <section className="rounded-md border">
        {/* Filters */}
        <div className="px-3 py-2 border-b bg-gray-50 grid gap-2 md:grid-cols-12">
          <div className="md:col-span-2 flex items-center gap-2">
            <span className="text-sm text-gray-700">Status</span>
            <select
              value={status}
              onChange={(e) => { setStatus(e.target.value as TxStatus | "all"); setTxPage(1); }}
              className="border rounded px-2 py-1 text-sm w-full"
            >
              <option value="all">All</option>
              <option value="pending">Pending</option>
              <option value="processed">Processed</option>
              <option value="failed">Failed</option>
            </select>
          </div>

          <div className="md:col-span-2 flex items-center gap-2">
            <span className="text-sm text-gray-700">Level</span>
            <select
              value={level}
              onChange={(e) => { setLevel(e.target.value as SourceLevel | "all"); setTxPage(1); }}
              className="border rounded px-2 py-1 text-sm w-full"
            >
              <option value="all">All</option>
              <option value="self">Self</option>
              <option value="l1">L1</option>
              <option value="l2">L2</option>
              <option value="l3">L3</option>
              <option value="downline">Downline</option>
            </select>
          </div>

          <div className="md:col-span-2 flex items-center gap-2">
            <span className="text-sm text-gray-700">₹ Min</span>
            <input
              type="number"
              value={amtMin}
              onChange={(e) => { setAmtMin(e.target.value); setTxPage(1); }}
              className="border rounded px-2 py-1 text-sm w-full"
              placeholder="0"
            />
          </div>

          <div className="md:col-span-2 flex items-center gap-2">
            <span className="text-sm text-gray-700">₹ Max</span>
            <input
              type="number"
              value={amtMax}
              onChange={(e) => { setAmtMax(e.target.value); setTxPage(1); }}
              className="border rounded px-2 py-1 text-sm w-full"
              placeholder="∞"
            />
          </div>

          <div className="md:col-span-3 flex items-center gap-2">
            <span className="text-sm text-gray-700">Ref / Type</span>
            <input
              type="text"
              value={refQuery}
              onChange={(e) => { setRefQuery(e.target.value); setTxPage(1); }}
              className="border rounded px-2 py-1 text-sm w-full"
              placeholder="Search ref or type…"
            />
          </div>

          <div className="md:col-span-1 flex items-center justify-end">
            <button
              onClick={() => setTxPage(1)}
              className="px-3 py-1 rounded border text-sm"
            >
              Apply
            </button>
          </div>
        </div>

        {/* Table */}
        <div className="p-3 overflow-x-auto">
          {loadingTx ? (
            <div className="text-sm text-gray-500">Loading transactions…</div>
          ) : txRows.length === 0 ? (
            <div className="text-sm text-gray-500">No transactions.</div>
          ) : (
            <table className="min-w-full text-sm">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-3 py-2 text-left">Date</th>
                  <th className="px-3 py-2 text-left">Type</th>
                  <th className="px-3 py-2 text-left">Source</th>
                  <th className="px-3 py-2 text-right">Amount (₹)</th>
                  <th className="px-3 py-2 text-left">Status</th>
                  <th className="px-3 py-2 text-left">Ref</th>
                </tr>
              </thead>
              <tbody className="divide-y">
                {txRows.map((r) => (
                  <tr key={r.id}>
                    <td className="px-3 py-2">{new Date(r.date).toLocaleDateString()}</td>
                    <td className="px-3 py-2 capitalize">{r.type}</td>
                    <td className="px-3 py-2 uppercase">{r.source}</td>
                    <td className="px-3 py-2 text-right">{formatINR(r.amount_inr)}</td>
                    <td className="px-3 py-2">
                      <span className={`px-2 py-1 rounded text-xs ${
                        r.status === "processed" ? "bg-green-100 text-green-800" :
                        r.status === "pending"   ? "bg-amber-100 text-amber-800" :
                                                   "bg-red-100 text-red-800"
                      }`}>
                        {r.status}
                      </span>
                    </td>
                    <td className="px-3 py-2 font-mono">{r.ref}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}

          {/* Simple pagination using exact total */}
          <div className="mt-3 flex items-center justify-end gap-2">
            <button
              onClick={() => setTxPage((p) => Math.max(1, p - 1))}
              className="px-3 py-1 rounded border text-sm"
              disabled={txPage <= 1}
            >
              Prev
            </button>
            <span className="text-xs text-gray-600">
              Page {txPage}{txTotal ? ` • ${txTotal} total` : ""}
            </span>
            <button
              onClick={() => setTxPage((p) => p + 1)}
              className="px-3 py-1 rounded border text-sm"
              disabled={txRows.length === 0 || (txPage * 25) >= txTotal}
            >
              Next
            </button>
          </div>
        </div>
      </section>

      {/* Search: Connectors Products (downline) */}
      <section className="rounded-md border">
        <div className="px-3 py-2 border-b bg-gray-50 flex items-center gap-2">
          <div className="text-lg font-semibold">Search: Connectors Products</div>
          <div className="ml-auto flex items-center gap-2">
            <input
              type="text"
              value={pQuery}
              onChange={(e) => setPQuery(e.target.value)}
              className="border rounded px-2 py-1 text-sm"
              placeholder="Search products, merchants, categories…"
            />
            <button onClick={runProductSearch} className="px-3 py-1 rounded border text-sm">
              Search
            </button>
          </div>
        </div>

        <div className="p-3 grid sm:grid-cols-2 lg:grid-cols-3 gap-3">
          {pLoading ? (
            <div className="text-sm text-gray-500">Searching…</div>
          ) : pResults.length === 0 ? (
            <div className="text-sm text-gray-500">No products found.</div>
          ) : (
            pResults.map((p) => (
              <div key={p.id} className="rounded-md border px-3 py-3 flex flex-col gap-2">
                <div className="font-semibold">{p.name}</div>
                <div className="text-xs text-gray-600">
                  {p.merchant} • {p.category}{p.location ? ` • ${p.location}` : ""}
                </div>
                <div className="text-sm">
                  <span className="px-2 py-0.5 rounded bg-blue-100 text-blue-800">
                    {p.discount_pct}% OFF
                  </span>
                </div>
                <div className="mt-auto flex items-center gap-2">
                  <button className="px-3 py-1 rounded border text-sm">Open</button>
                  <button
                    className="px-3 py-1 rounded border text-sm opacity-60 cursor-not-allowed"
                    title="Admin-gated: enable when permissions & backend ready"
                    disabled
                  >
                    Edit
                  </button>
                </div>
              </div>
            ))
          )}
        </div>
      </section>
    </div>
  );
}
