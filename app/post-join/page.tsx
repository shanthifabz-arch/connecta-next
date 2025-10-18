"use client";

import React, { Suspense, useEffect, useMemo, useState } from "react";
import dynamic from "next/dynamic";
import { useSearchParams } from "next/navigation";


const ShopPanel = dynamic(
  () => import('./ShopPanel').then(m => m.default), // ensure React gets the component, not the module
  {
    ssr: false,
    loading: () => <div className="p-4 text-sm text-gray-500">Loading Online Purchases…</div>,
  }
);
// Lazy-load panels
const AdminPanel = dynamic(() => import("./AdminPanel"), { ssr: false });
const DashboardPanel = dynamic(() => import("./DashboardPanel"), { ssr: false });
const PaymentsPanel = dynamic(() => import("./PaymentsPanel"), { ssr: false });



/* -------------------------------------------
   Shared helpers
-------------------------------------------- */
const copy = (text: string) => navigator.clipboard.writeText(text);

/** compress any run of digits like "000000004" → "4" */
function compactReferral(raw: string): string {
  const s = String(raw || "");
  if (!s) return s;
  return s.replace(/\d+/g, (m) => String(parseInt(m, 10)));
}

/* -------------------------------------------
   Types (mirror future Supabase contracts)
-------------------------------------------- */
type PeriodKey = "yesterday" | "last7" | "prev7" | "last30" | "uptoLastMonth";
export type TreeLevel = 1 | 2 | 3 | 4 | 5;

export interface ConnectorLite {
  id: string;
  ref: string;
  name: string;
  phone?: string | null;
  joined_at: string;       // ISO
  region?: string | null;  // "India • Tamil Nadu"
}

export interface L1Metrics extends ConnectorLite {
  adds_yesterday: number;
  adds_7d: number;
  adds_30d: number;
  total_descendants: number;
}

// Growth Metrics → Details drawer
interface AddsDetailRow {
  child_ref: string;
  child_name: string;
  date: string; // ISO
  adds: number;
}

export interface GrowthSummary {
  l1_added: Record<PeriodKey, number>;
  l1_trend_pct: Record<PeriodKey, number>;
}

export interface LevelOverviewItem {
  level: TreeLevel;
  total: number;
  new_in_period: number;
  active: number;
  dormant: number;
}

// Level overview → member list rows
interface LevelMemberRow {
  id: string;
  ref: string;
  name: string;
  joined_at: string;         // ISO
  adds_7d: number;
  adds_30d: number;
  total_descendants: number;
  level: number;
}
type LevelFilter = "all" | "new" | "active" | "dormant";

// Tier labels
type Tier = "Good" | "Average" | "Poor";

/* -------------------------------------------
   API CALLS — wired to Supabase RPCs (read-only)
-------------------------------------------- */
import { getSupabaseBrowser } from "@/lib/supabase-browser";
const supabase = getSupabaseBrowser();





// --- RPC helpers (normalize & map) ---
const normalizeRefForRpc = (ref: string) =>
  decodeURIComponent(String(ref || "")).replace(/\s+/g, "_").trim();

const mapPeriodToDb = (p: PeriodKey): string => {
  switch (p) {
    case "yesterday":     return "yesterday";
    case "last7":         return "7d";
    case "prev7":         return "prev7";
    case "last30":        return "30d";
    case "uptoLastMonth": return "upto_last_month";
  }
};

const coalesceSummary = (row: any) => ({
  yesterday:       Number(row?.yesterday ?? 0),
  last7:           Number(row?.last7 ?? 0),
  prev7:           Number(row?.prev7 ?? 0),
  last30:          Number(row?.last30 ?? 0),
  upto_last_month: Number(row?.upto_last_month ?? 0),
});

const pct = (a: number, b: number) => (b ? ((a - b) / b) * 100 : (a ? 100 : 0));

// 1) Load my CONNECTA global id by ref/id
async function api_fetchGlobalId(params: { id?: string; ref?: string }) {
  const rpcRef = params.ref ? normalizeRefForRpc(params.ref) : null;
  const { data, error } = await supabase
    .rpc("get_global_id", { p_id: params.id ?? null, p_ref: rpcRef })
    .single();
  if (error) return { global_connecta_id: "" };
  return { global_connecta_id: data?.global_connecta_id ?? "" };
}


// 2) Growth summary

async function api_fetchGrowthSummary(params: { myRef: string }): Promise<GrowthSummary> {
  const rpcRef = normalizeRefForRpc(params.myRef || "");
  if (!rpcRef) {
    return {
      l1_added:     { yesterday: 0, last7: 0, prev7: 0, last30: 0, uptoLastMonth: 0 },
      l1_trend_pct: { yesterday: 0, last7: 0, prev7: 0, last30: 0, uptoLastMonth: 0 },
    };
  }
  const { data, error } = await supabase.rpc("growth_summary", { p_ref: rpcRef }).single();
  const row = (!error && data) ? coalesceSummary(data) : coalesceSummary(null);

  return {
    l1_added: {
      yesterday: row.yesterday,
      last7: row.last7,
      prev7: row.prev7,
      last30: row.last30,
      uptoLastMonth: row.upto_last_month,
    },
    l1_trend_pct: {
      yesterday:     pct(row.yesterday, 0),
      last7:         pct(row.last7, row.prev7),
      prev7:         0,
      last30:        pct(row.last30, row.upto_last_month),
      uptoLastMonth: 0,
    },
  };
}


// 3) Level overview (L1–L5)

async function api_fetchLevelOverview(params: { myRef: string; period: PeriodKey; }): Promise<LevelOverviewItem[]> {
  const rpcRef = normalizeRefForRpc(params.myRef || "");
  if (!rpcRef) return [];
  const periodDb = mapPeriodToDb(params.period);
  const { data, error } = await supabase
    .rpc("level_overview", { p_ref: rpcRef, p_period: periodDb });
  return (error || !data) ? [] : data;
}

// AA unlock (DB: connecta_api.aa_unlock_status → public wrapper)
// Returns whether the user is AA, their business %, and if Connectors tab is unlocked.

async function api_fetchAaUnlock(params: { ref: string }): Promise<{
  isAA: boolean;
  businessPct: number;
  unlocked: boolean;
}> {
  // Use the canonical normalizer if you already inserted it earlier
  const rpcRef = (typeof normalizeRefForRpc === "function")
    ? normalizeRefForRpc(params.ref || "")
    : String(params.ref || "").replace(/\s+/g, "_"); // minimal fallback

  if (!rpcRef) return { isAA: false, businessPct: 0, unlocked: false };

  

  // IMPORTANT: .rpc() returns data directly — do NOT chain .select()
  const { data, error } = await supabase.rpc("aa_unlock_status", { p_ref: rpcRef });

  if (error || !data) {
    console.error("aa_unlock_status failed:", error);
    return { isAA: false, businessPct: 0, unlocked: false };
  }

  return {
    isAA: !!(data.isaa ?? data.is_aa),
    businessPct: Number(data.businesspct ?? data.business_pct ?? 0),
    unlocked: !!(data.unlocked ?? data.is_unlocked ?? false),
  };
}

// 4) L1 leaderboard & list

async function api_fetchL1Metrics(params: {
  myRef: string; period: PeriodKey; page?: number; pageSize?: number;
}): Promise<L1Metrics[]> {
  const rpcRef = normalizeRefForRpc(params.myRef || "");
  if (!rpcRef) return [];
  const page     = params.page ?? 1;
  const pageSize = params.pageSize ?? 50;
  const { data, error } = await supabase
    .rpc("l1_leaderboard", {
      p_ref: rpcRef,
      p_period: mapPeriodToDb(params.period),
      p_limit: pageSize,
      p_offset: (page - 1) * pageSize
    });
  if (error || !data) return [];
  return data.map((r: any) => ({
    id: r.id, ref: r.ref, name: r.name, phone: r.phone,
    joined_at: r.joined_at, region: r.region,
    adds_yesterday: r.adds_yesterday, adds_7d: r.adds_7d, adds_30d: r.adds_30d,
    total_descendants: r.total_descendants
  }));
}


// Growth Metrics → Details drawer (keep simple until a dedicated RPC exists)
async function api_fetchAddsDetail(_params: {
  myRef: string; period: PeriodKey; page?: number; pageSize?: number;
}): Promise<AddsDetailRow[]> {
  return [];
}

// Level overview → members

async function api_fetchLevelMembers(params: {
  myRef: string; level: number; filter: LevelFilter; period: PeriodKey; page?: number; pageSize?: number;
}): Promise<LevelMemberRow[]> {
  const rpcRef = normalizeRefForRpc(params.myRef || "");
  if (!rpcRef) return [];
  const { data, error } = await supabase.rpc("level_members", {
    p_ref: rpcRef,
    p_level: params.level,
    p_filter: params.filter,
    p_period: mapPeriodToDb(params.period),
    p_limit: params.pageSize ?? 50,
    p_offset: ((params.page ?? 1) - 1) * (params.pageSize ?? 50),
  });
  return (error || !data) ? [] : data;
}

// 5) Save “Progress Status” note (write to connecta_api)
async function api_saveProgressStatus(params: { myRef: string; text: string }): Promise<{ ok: true }> {
  const today = new Date().toISOString().slice(0,10);
  if (!params.myRef) return { ok: true };
  const { error } = await supabase.rpc("save_progress_note", {
    p_ref: params.myRef, p_date: today, p_text: params.text
  });
  if (error) throw error;
  return { ok: true as const };
}


/* -------------------------------------------
   Component
-------------------------------------------- */
function PostJoinPageInner() {
  const sp = useSearchParams();

  // URL params
  const id = sp?.get("id") ?? "";
  const ref = sp?.get("ref") ?? "";
  const country = sp?.get("country") ?? "";
  const state = sp?.get("state") ?? "";
  const mobile = sp?.get("mobile") ?? "";
  const recovery = sp?.get("recovery") ?? "";
  const connectaIdFromQS = sp?.get("connectaId") ?? "";
  // Use one canonical ref for all RPCs (decode + underscores)
const rpcRef = useMemo(() => normalizeRefForRpc(ref), [ref]);


  // global id
  const [globalId, setGlobalId] = useState<string>(connectaIdFromQS);
  const [gidLoading, setGidLoading] = useState(false);

  // active top tab
  const [activeTab, setActiveTab] = useState<"add" | "admin" | "dash" | "shop" | "pay">("add");

  // Pretty referral for UI
  const prettyRef = useMemo(() => compactReferral(ref), [ref]);

  // Invite message
  const inviteMessage = useMemo(() => {
    const head = "You are invited to Join CONNECTA Community.";
    const mid = "Please download our App and join with this referral code:";
    return `${head}\n${mid} ${prettyRef || "—"}`;
  }, [prettyRef]);

  // Toast
  const [showToast, setShowToast] = useState(true);
  useEffect(() => {
    const t = setTimeout(() => setShowToast(false), 2500);
    return () => clearTimeout(t);
  }, []);
const [aaUnlock, setAaUnlock] = useState<{isAA:boolean; businessPct:number; unlocked:boolean} | null>(null);

const tabs = [
  { key: "add", label: "ADD CONNECTORS" },
  { key: "admin", label: "ADMIN" },
  { key: "dash", label: "DASHBOARD" },
  { key: "shop", label: "ONLINE PURCHASES" },
  { key: "pay", label: "PAYMENTS" },
] as const;



  /* --------- Tab 1 (Add Connectors) state --------- */
  const [period, setPeriod] = useState<PeriodKey>("last30");
  const [growth, setGrowth] = useState<GrowthSummary | null>(null);
  const [levels, setLevels] = useState<LevelOverviewItem[]>([]);
  const [l1Rows, setL1Rows] = useState<L1Metrics[]>([]);
  const [tierFilter, setTierFilter] = useState<Tier | "All">("All");
  const [statusNote, setStatusNote] = useState<string>("");

  // Growth details drawer
  const [detailOpen, setDetailOpen] = useState(false);
  const [detailPeriod, setDetailPeriod] = useState<PeriodKey | null>(null);
  const [addsDetail, setAddsDetail] = useState<AddsDetailRow[]>([]);
  const [detailLoading, setDetailLoading] = useState(false);

  // Level members drawer
  const [lvlOpen, setLvlOpen] = useState(false);
  const [lvlLoading, setLvlLoading] = useState(false);
  const [lvlSelected, setLvlSelected] = useState<{ level: number; filter: LevelFilter } | null>(null);
  const [lvlRows, setLvlRows] = useState<LevelMemberRow[]>([]);

  // Logbook
  const [noteDate, setNoteDate] = useState<string>(() => new Date().toISOString().slice(0, 10));
  const [notesList, setNotesList] = useState<Array<{ date: string; text: string; updated_at: string }>>([]);

  // Load global id
  useEffect(() => {
    let alive = true;
    (async () => {
      setGidLoading(true);
      try {
        const { global_connecta_id } = await api_fetchGlobalId({ id: id || undefined, ref: ref || undefined });
        if (alive) setGlobalId(global_connecta_id || connectaIdFromQS || "");
      } catch {
        if (alive) setGlobalId(connectaIdFromQS || "");
      } finally {
        if (alive) setGidLoading(false);
      }
    })();
    return () => { alive = false; };
  }, [id, ref, connectaIdFromQS]);

// Load Tab 1 data
useEffect(() => {
  let alive = true;
  (async () => {
    const myRef = rpcRef || "";
    if (!myRef) {
      if (alive) { setGrowth(null); setLevels([]); setL1Rows([]); }
      return;
    }
    const [g, lvls, l1] = await Promise.all([
      api_fetchGrowthSummary({ myRef }),
      api_fetchLevelOverview({ myRef, period }),
      api_fetchL1Metrics({ myRef, period, page: 1, pageSize: 50 }),
    ]);
    if (!alive) return;
    setGrowth(g);
    setLevels(lvls);
    setL1Rows(l1);
  })();
  return () => { alive = false; };
}, [rpcRef, period]); // note: depend on rpcRef, not raw ref


// if you created: const rpcRef = useMemo(() => normalizeRefForRpc(ref), [ref]);
useEffect(() => {
  let alive = true;
  (async () => {
    try {
      const r = await api_fetchAaUnlock({ ref: rpcRef || "" }); // use rpcRef
      if (alive) setAaUnlock(r);
    } catch {
      if (alive) setAaUnlock(null);
    }
  })();
  return () => { alive = false; };
}, [rpcRef]); // depend on rpcRef



  // Load saved logbook entries
  useEffect(() => {
    const key = `connecta_logbook_${ref || "anon"}`;
    try {
      const list = JSON.parse(localStorage.getItem(key) || "[]");
      if (Array.isArray(list)) {
        setNotesList(list);
        const cur = list.find((r: any) => r?.date === noteDate);
        setStatusNote(cur?.text || "");
      } else {
        setNotesList([]);
        setStatusNote("");
      }
    } catch {
      setNotesList([]);
      setStatusNote("");
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [ref]);

  // Prefill text when date changes
  useEffect(() => {
    const cur = notesList.find((r) => r.date === noteDate);
    setStatusNote(cur?.text || "");
  }, [noteDate, notesList]);

  // Tiering
  const l1WithTiers = useMemo(() => {
    const base = [...l1Rows].sort((a, b) => b.adds_30d - a.adds_30d);
    const n = base.length;
    if (!n) return [] as (L1Metrics & { tier: Tier })[];
    const goodEnd = Math.max(1, Math.ceil(n * 0.23));
    const avgEnd  = Math.max(goodEnd + 1, Math.ceil(n * 0.64)); // 23% + 41% = 64%
    return base.map((row, idx) => {
      let tier: Tier = "Poor";
      if (idx < goodEnd) tier = "Good";
      else if (idx < avgEnd) tier = "Average";
      return { ...row, tier };
    });
  }, [l1Rows]);

  const l1Filtered = useMemo(() => {
    if (tierFilter === "All") return l1WithTiers;
    return l1WithTiers.filter((r) => r.tier === tierFilter);
  }, [l1WithTiers, tierFilter]);

  const periodLabel: Record<PeriodKey, string> = {
    yesterday: "Yesterday",
    last7: "Last 7 days",
    prev7: "Previous 7 days",
    last30: "Last 30 days",
    uptoLastMonth: "Up to Last Month",
  };

  async function saveStatus() {
    const text = (statusNote || "").trim();
    if (!text) return alert("Write a short note before saving.");
    const key = `connecta_logbook_${ref || "anon"}`;
    let list: Array<{ date: string; text: string; updated_at: string }> = [];
    try {
      list = JSON.parse(localStorage.getItem(key) || "[]");
      if (!Array.isArray(list)) list = [];
    } catch {
      list = [];
    }
    const isoNow = new Date().toISOString();
    const idx = list.findIndex((r) => r.date === noteDate);
    if (idx >= 0) list[idx] = { date: noteDate, text, updated_at: isoNow };
    else list.unshift({ date: noteDate, text, updated_at: isoNow });
    try { localStorage.setItem(key, JSON.stringify(list)); } catch {}
    setNotesList(list);
    await api_saveProgressStatus({ myRef: ref || "", text }); // stub (no-op)
    alert("Saved locally. We’ll sync this to Supabase later.");
  }

  // Tabs bar (centered, wraps nicely)
const TabsBar = () => (
  <div className="mx-auto max-w-6xl mb-6">
    <div
      role="tablist"
      aria-label="Post-join sections"
      className="flex flex-wrap gap-2 justify-center md:justify-start"
    >
      {tabs.map((t) => {
        const active = activeTab === t.key;
        return (
          <button
            key={t.key}
            role="tab"
            aria-selected={active}
            onClick={() => setActiveTab(t.key as any)}
            type="button"
            className={[
              // make each pill narrower, but readable
              "basis-[112px] sm:basis-[132px] lg:basis-[152px]",
              "grow sm:grow-0 shrink-0",
              "rounded-full border px-4 py-2",
              "text-xs sm:text-[13px] leading-tight",
              "transition",
              active
                ? "bg-blue-600 text-white border-blue-600"
                : "bg-white text-black border-gray-300 hover:bg-gray-50"
            ].join(" ")}
          >
            {t.label}
          </button>
        );
      })}
    </div>
  </div>
);



  return (
    <div className="min-h-screen bg-white text-black px-4 py-6">
      {/* Toast */}
      {showToast && (
        <div className="fixed left-1/2 top-4 -translate-x-1/2 z-20">
          <div className="animate-fade-in-out rounded-full bg-blue-600 text-white px-4 py-2 shadow-lg">
            You&apos;re in 🎉 &nbsp; <span className="opacity-90">{country || "—"} • {state || "—"}</span>
          </div>
          <style jsx>{`
            @keyframes fadeInOut {
              0% { opacity: 0; transform: translate(-50%, -6px); }
              15% { opacity: 1; transform: translate(-50%, 0px); }
              85% { opacity: 1; transform: translate(-50%, 0px); }
              100% { opacity: 0; transform: translate(-50%, -6px); }
            }
            .animate-fade-in-out { animation: fadeInOut 2.4s ease forwards; }
          `}</style>
        </div>
      )}

      <div className="max-w-6xl mx-auto">
        <TabsBar />

       {/* Tab content (Admin / Dashboard / Shop / Payments / Add-Connectors) */}
{activeTab === "admin" ? (
  <AdminPanel
    refCode={ref}
    myGlobalId={globalId}
    country={country}
    state={state}
  />
) : activeTab === "dash" ? (
  <DashboardPanel refCode={ref} />
) : activeTab === "shop" ? (
  <ShopPanel refCode={globalId} />
) : activeTab === "pay" ? (

  <PaymentsPanel refCode={ref} />
) : (
  <>


           {/* Snapshot (compact + actions) */}
<div className="rounded-md border border-blue-200 bg-blue-50 text-blue-900 px-3 py-3 mb-4">
  <div className="grid grid-cols-1 md:grid-cols-3 gap-3 items-start">
    {/* Left: key facts */}
    <div className="md:col-span-2">
      <div className="grid grid-cols-[150px,1fr] md:grid-cols-[200px,1fr] gap-y-1 text-xs md:text-sm items-center">
        <div className="font-semibold uppercase tracking-wide">GLOBAL CONNECTA ID</div>
        <div className="text-right font-mono font-bold truncate" title={(globalId || '-') as string} aria-live="polite">
          {gidLoading ? "loading…" : (globalId || "—")}
        </div>

        <div className="font-semibold uppercase tracking-wide">REFERRAL CODE</div>
        <div className="text-right font-mono font-bold truncate" title={(compactReferral(ref) || '-') as string}>
          {compactReferral(ref) || "—"}
        </div>

        <div className="font-semibold uppercase tracking-wide">PRIMARY PHONE</div>
        <div className="text-right font-mono font-bold truncate" title={(mobile || '-') as string}>
          {mobile || "—"}
        </div>

        <div className="font-semibold uppercase tracking-wide">RECOVERY PHONE</div>
        <div className="text-right font-mono font-bold truncate" title={(recovery || '-') as string}>
          {recovery || "—"}
        </div>

        <div className="font-semibold uppercase tracking-wide">REGION</div>
        <div className="text-right font-bold truncate" title={`${country || '-'} • ${state || '-'}`}>
          {(country || "—")} • {(state || "—")}
        </div>
      </div>
    </div>

    {/* Right: actions (better responsive) */}
    <div className="flex flex-col md:flex-row gap-2">
      <button
        onClick={() => copy(compactReferral(ref)).then(() => alert("Referral code copied!"))}
        className="md:flex-1 rounded-md bg-blue-100 px-3 py-2 text-xs md:text-sm disabled:opacity-50"
        disabled={!ref}
        aria-label="Copy referral code"
      >
        Copy referral code
      </button>

      <button
        onClick={() => copy(inviteMessage).then(() => alert("Invite message copied!"))}
        className="md:flex-1 rounded-md bg-gray-100 px-3 py-2 text-xs md:text-sm"
        aria-label="Copy invite message"
      >
        Copy invite message
      </button>

      <button
        onClick={() => window.open(`https://wa.me?text=${encodeURIComponent(inviteMessage)}`, "_blank")}
        className="md:flex-1 rounded-md bg-green-200 px-3 py-2 text-xs md:text-sm"
        aria-label="Share on WhatsApp"
      >
        Share on WhatsApp
      </button>
    </div>
  </div>
</div>

                 

            {/* Logbook (day-wise) */}
            <div className="mb-8">
              <div className="flex flex-wrap items-end gap-3 mb-2">
                <label className="text-sm font-medium text-gray-800">Progress log (private)</label>
                <div className="ml-auto flex items-center gap-2">
                  <span className="text-xs text-gray-600">Date</span>
                  <input
                    type="date"
                    value={noteDate}
                    onChange={(e) => setNoteDate(e.target.value)}
                    className="border rounded-md px-2 py-1 text-sm"
                  />
                </div>
              </div>

              <textarea
                value={statusNote}
                onChange={(e) => setStatusNote(e.target.value)}
                rows={3}
                placeholder="Write a short update about your outreach, plans, obstacles, etc."
                className="w-full border rounded-md p-3"
              />
              <div className="mt-2 flex gap-2">
                <button onClick={saveStatus} className="px-4 py-2 rounded-md bg-blue-600 text-white">
                  Save log entry
                </button>
                <span className="text-xs text-gray-500 self-center">
                  Saved locally by date; we’ll sync to Supabase later.
                </span>
              </div>

              <div className="mt-4 border rounded-md overflow-hidden">
                <div className="bg-gray-50 px-3 py-2 text-xs text-gray-600">Recent entries (latest first)</div>
                <div className="divide-y">
                  {notesList.length === 0 ? (
                    <div className="px-3 py-4 text-sm text-gray-500">No entries yet.</div>
                  ) : (
                    notesList.slice(0, 10).map((r) => (
                      <div key={r.date} className="px-3 py-2 flex items-center gap-3">
                        <div className="text-xs text-gray-600 w-[110px]">{r.date}</div>
                        <div className="flex-1 text-sm line-clamp-2">{r.text}</div>
                        <div className="text-[10px] text-gray-400">updated {new Date(r.updated_at).toLocaleString()}</div>
                      </div>
                    ))
                  )}
                </div>
              </div>
            </div>
{/* Growth Metrics */}
<div className="mb-10">
  {/* Title above the pills (unchanged outer width) */}
  <h3 className="text-lg font-semibold mb-2">Growth metrics</h3>

  {/* Pills: keep container full width, just make the pills themselves smaller */}
  <div className="w-full">
    <div className="w-full overflow-x-auto">
      <div
        role="tablist"
        aria-label="Growth period"
        className="inline-flex flex-nowrap rounded-full border border-gray-300 overflow-hidden
                   justify-center"
        style={{ width: "100%" }}
      >
        {(["yesterday","last7","prev7","last30","uptoLastMonth"] as PeriodKey[]).map((p, idx, arr) => {
          const active = period === p;
          const notLast = idx < arr.length - 1;
          return (
            <button
              key={p}
              role="tab"
              aria-selected={active}
              onClick={() => setPeriod(p)}
              type="button"
              className={`px-2 py-1 text-xs md:text-[12px] whitespace-nowrap transition
                focus:outline-none focus:ring-2 focus:ring-blue-400
                ${active ? "bg-blue-600 text-white" : "bg-white text-gray-900 hover:bg-gray-50"}
                ${notLast ? "border-r border-gray-300" : ""}`}
            >
              {periodLabel[p]}
            </button>
          );
        })}
      </div>
    </div>
  </div>

  {/* Cards area: keep full width; shrink inner content of each card to ~80% */}
  <div className="w-full mt-4">
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4 auto-rows-fr">
      {growth ? (
        (Object.keys(growth.l1_added) as PeriodKey[]).map((k) => (
          <button
            key={k}
            onClick={async () => {
              setDetailPeriod(k);
              setDetailLoading(true);
              setDetailOpen(true);
              try {
                const rows = await api_fetchAddsDetail({ myRef: ref || "", period: k, page: 1, pageSize: 50 });
                setAddsDetail(rows);
              } finally {
                setDetailLoading(false);
              }
            }}
            title={`View details for ${periodLabel[k]}`}
            className="h-full rounded-md border p-3 text-left hover:bg-gray-50 transition cursor-pointer
                       min-h-[140px] flex"
          >
            {/* Inner content reduced to 80% width */}
            <div className="mx-auto w-4/5 flex flex-col justify-between">
              <div className="text-xs text-gray-500 flex items-start justify-between gap-2">
                <span>{periodLabel[k]}</span>
                <span className="text-[10px] text-gray-400 underline">Details</span>
              </div>

              <div className="mt-1 text-2xl font-bold">{growth.l1_added[k]}</div>

              <div className={`mt-1 text-xs ${growth.l1_trend_pct[k] >= 0 ? "text-green-700" : "text-red-700"}`}>
                {growth.l1_trend_pct[k] >= 0 ? "▲" : "▼"} {Math.abs(growth.l1_trend_pct[k])}%
              </div>
            </div>
          </button>
        ))
      ) : (
        <div className="text-sm text-gray-500">Loading metrics…</div>
      )}
    </div>
  </div>
</div>


            {/* Drawer: Adds detail */}
            {detailOpen && (
              <div className="fixed inset-0 z-30">
                <div className="absolute inset-0 bg-black/30" onClick={() => setDetailOpen(false)} />
                <div className="absolute right-0 top-0 h-full w-full max-w-xl bg-white shadow-2xl flex flex-col">
                  <div className="px-4 py-3 border-b flex items-center gap-3">
                    <div className="text-lg font-semibold">
                      Adds detail — {detailPeriod ? periodLabel[detailPeriod] : ""}
                    </div>
                    <button className="ml-auto px-3 py-1 rounded border" onClick={() => setDetailOpen(false)}>Close</button>
                  </div>
                  <div className="p-3 overflow-auto flex-1">
                    {detailLoading ? (
                      <div className="text-sm text-gray-500">Loading…</div>
                    ) : addsDetail.length === 0 ? (
                      <div className="text-sm text-gray-500">No records for this period.</div>
                    ) : (
                      <table className="min-w-full text-sm">
                        <thead className="bg-gray-50">
                          <tr>
                            <th className="px-3 py-2 text-left">Child</th>
                            <th className="px-3 py-2 text-left">Referral</th>
                            <th className="px-3 py-2 text-left">Date</th>
                            <th className="px-3 py-2 text-right">Adds</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y">
                          {addsDetail.map((r, idx) => (
                            <tr key={`${r.child_ref}-${idx}`}>
                              <td className="px-3 py-2"><div className="font-medium">{r.child_name}</div></td>
                              <td className="px-3 py-2 font-mono">{r.child_ref}</td>
                              <td className="px-3 py-2">{new Date(r.date).toLocaleDateString()}</td>
                              <td className="px-3 py-2 text-right">{r.adds}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    )}
                  </div>
                </div>
              </div>
            )}

            {/* Level Overview */}
            <div className="mb-8">
              <div className="flex items-center gap-3 mb-3">
                <h3 className="text-lg font-semibold">Level overview</h3>
                <span className="text-sm text-gray-500">New = {periodLabel[period]}</span>
              </div>
              <div className="grid md:grid-cols-3 lg:grid-cols-5 gap-3">
                {levels.map((lv) => (
                  <div key={lv.level} className="rounded-md border px-3 py-3">
                    <div className="flex items-center justify-between">
                      <div className="text-xs text-gray-500">Level {lv.level}</div>
                      <button
                        className="text-[11px] underline text-gray-500"
                        title="View all"
                        onClick={async () => {
                          setLvlSelected({ level: lv.level, filter: "all" });
                          setLvlLoading(true); setLvlOpen(true);
                          const rows = await api_fetchLevelMembers({ myRef: ref || "", level: lv.level, filter: "all", period, page: 1, pageSize: 50 });
                          setLvlRows(rows); setLvlLoading(false);
                        }}
                      >
                        Details
                      </button>
                    </div>

                    <button
                      className="w-full text-left"
                      title="View all"
                      onClick={async () => {
                        setLvlSelected({ level: lv.level, filter: "all" });
                        setLvlLoading(true); setLvlOpen(true);
                        const rows = await api_fetchLevelMembers({ myRef: ref || "", level: lv.level, filter: "all", period, page: 1, pageSize: 50 });
                        setLvlRows(rows); setLvlLoading(false);
                      }}
                    >
                      <div className="text-2xl font-bold">{lv.total}</div>
                    </button>

                    <div className="mt-1 space-y-0.5">
                      <button
                        className="block text-xs text-blue-700 hover:underline"
                        onClick={async () => {
                          setLvlSelected({ level: lv.level, filter: "new" });
                          setLvlLoading(true); setLvlOpen(true);
                          const rows = await api_fetchLevelMembers({ myRef: ref || "", level: lv.level, filter: "new", period, page: 1, pageSize: 50 });
                          setLvlRows(rows); setLvlLoading(false);
                        }}
                      >
                        New: {lv.new_in_period}
                      </button>
                      <button
                        className="block text-xs text-green-700 hover:underline"
                        onClick={async () => {
                          setLvlSelected({ level: lv.level, filter: "active" });
                          setLvlLoading(true); setLvlOpen(true);
                          const rows = await api_fetchLevelMembers({ myRef: ref || "", level: lv.level, filter: "active", period, page: 1, pageSize: 50 });
                          setLvlRows(rows); setLvlLoading(false);
                        }}
                      >
                        Active: {lv.active}
                      </button>
                      <button
                        className="block text-xs text-gray-600 hover:underline"
                        onClick={async () => {
                          setLvlSelected({ level: lv.level, filter: "dormant" });
                          setLvlLoading(true); setLvlOpen(true);
                          const rows = await api_fetchLevelMembers({ myRef: ref || "", level: lv.level, filter: "dormant", period, page: 1, pageSize: 50 });
                          setLvlRows(rows); setLvlLoading(false);
                        }}
                      >
                        Dormant: {lv.dormant}
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Drawer: Level members */}
            {lvlOpen && (
              <div className="fixed inset-0 z-30">
                <div className="absolute inset-0 bg-black/30" onClick={() => setLvlOpen(false)} />
                <div className="absolute right-0 top-0 h-full w-full max-w-2xl bg-white shadow-2xl flex flex-col">
                  <div className="px-4 py-3 border-b flex items-center gap-3">
                    <div className="text-lg font-semibold">
                      Level {lvlSelected?.level} — {lvlSelected?.filter.toUpperCase()}
                    </div>
                    <button className="ml-auto px-3 py-1 rounded border" onClick={() => setLvlOpen(false)}>Close</button>
                  </div>

                  <div className="p-3 overflow-auto flex-1">
                    {lvlLoading ? (
                      <div className="text-sm text-gray-500">Loading…</div>
                    ) : lvlRows.length === 0 ? (
                      <div className="text-sm text-gray-500">No members found.</div>
                    ) : (
                      <table className="min-w-full text-sm">
                        <thead className="bg-gray-50">
                          <tr>
                            <th className="px-3 py-2 text-left">Name / ID</th>
                            <th className="px-3 py-2 text-left">Referral</th>
                            <th className="px-3 py-2 text-left">Joined</th>
                            <th className="px-3 py-2 text-right">Adds (7d / 30d)</th>
                            <th className="px-3 py-2 text-right">Descendants</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y">
                          {lvlRows.map((r) => (
                            <tr key={r.id}>
                              <td className="px-3 py-2">
                                <div className="font-medium">{r.name}</div>
                                <div className="text-xs text-gray-500">{r.id}</div>
                              </td>
                              <td className="px-3 py-2 font-mono">{r.ref}</td>
                              <td className="px-3 py-2">{new Date(r.joined_at).toLocaleDateString()}</td>
                              <td className="px-3 py-2 text-right">{r.adds_7d} / {r.adds_30d}</td>
                              <td className="px-3 py-2 text-right">{r.total_descendants}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    )}
                  </div>
                </div>
              </div>
            )}

            {/* L1 Leaderboard + Filter */}
            <div className="mb-3 flex flex-wrap items-center gap-2">
              <h3 className="text-lg font-semibold">Children (L1) Leaderboard</h3>
              <span className="text-sm text-gray-500">Ranked by adds in last 30 days</span>
              <div className="ml-auto flex gap-2">
                {(["All","Good","Average","Poor"] as (Tier | "All")[]).map(t => (
                  <button
                    key={t}
                    onClick={() => setTierFilter(t)}
                    className={`px-3 py-1 rounded-full border text-sm ${
                      tierFilter === t ? "bg-blue-600 text-white border-blue-600" : "bg-white border-gray-300"
                    }`}
                  >
                    {t}
                  </button>
                ))}
              </div>
            </div>

            {/* L1 List */}
            <div className="overflow-x-auto rounded-md border">
              <table className="min-w-full text-sm">
                <thead className="bg-gray-50 text-gray-700">
                  <tr>
                    <th className="px-3 py-2 text-left">Name / ID</th>
                    <th className="px-3 py-2 text-left">Referral</th>
                    <th className="px-3 py-2 text-left">Joined</th>
                    <th className="px-3 py-2 text-right">Adds (Y / 7d / 30d)</th>
                    <th className="px-3 py-2 text-right">Descendants</th>
                    <th className="px-3 py-2 text-left">Tier</th>
                    <th className="px-3 py-2 text-left">Region</th>
                    <th className="px-3 py-2">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {l1Filtered.map((r) => (
                    <tr key={r.id} className="border-t">
                      <td className="px-3 py-2">
                        <div className="font-medium">{r.name}</div>
                        <div className="text-xs text-gray-500">{r.id}</div>
                      </td>
                      <td className="px-3 py-2 font-mono">{r.ref}</td>
                      <td className="px-3 py-2">{new Date(r.joined_at).toLocaleDateString()}</td>
                      <td className="px-3 py-2 text-right">
                        {r.adds_yesterday} / {r.adds_7d} / {r.adds_30d}
                      </td>
                      <td className="px-3 py-2 text-right">{r.total_descendants}</td>
                      <td className="px-3 py-2">
                        <span className={`px-2 py-1 rounded text-xs ${
                          (r as any).tier === "Good" ? "bg-green-100 text-green-800" :
                          (r as any).tier === "Average" ? "bg-amber-100 text-amber-800" :
                          "bg-gray-100 text-gray-700"
                        }`}>{(r as any).tier}</span>
                      </td>
                      <td className="px-3 py-2">{r.region || "—"}</td>
                      <td className="px-3 py-2">
                        <div className="flex gap-2">
                          <button className="px-2 py-1 text-xs rounded border">View</button>
                          <button className="px-2 py-1 text-xs rounded border">Message</button>
                        </div>
                      </td>
                    </tr>
                  ))}
                  {l1Filtered.length === 0 && (
                    <tr>
                      <td className="px-3 py-6 text-center text-gray-500" colSpan={8}>
                        No children yet in this tier.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>

            <div className="h-8" />
          </>
        )}
      </div>
    </div>
  );
}
export default function PostJoinPage() {
  return (
    <Suspense fallback={<div className="p-4 text-sm text-gray-600">Loading…</div>}>
      <PostJoinPageInner />
    </Suspense>
  );
}



