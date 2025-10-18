"use client";

import React, { useEffect, useMemo, useState } from "react";
import BusinessForm from "@/components/forms/BusinessForm";
import { createClient } from "@supabase/supabase-js";
import {
  ResponsiveContainer,
  BarChart,
  CartesianGrid,
  XAxis,
  YAxis,
  Tooltip,
  Legend,
  Bar,
} from "recharts";



/**
 * CONNECTA Admin Panel — Expanded to spec (02-10-2025)
 * Pure client UI (no backend calls yet).
 */

// —— Types ——

type AdminSub = "reports" | "edit" | "promos" | "feedback" | "wellness";

export type Props = {
  refCode: string;       // parent’s referral (tree root for this admin)
  myGlobalId?: string;
  country?: string;      // e.g., IN
  state?: string;        // e.g., TN
  currency?: string;     // e.g., "INR"
};

type Category = "INDIVIDUAL" | "B2B" | "B2C" | "EXPORT" | "IMPORT";

type TimePreset =
  | "WEEKLY"
  | "FORTNIGHTLY"
  | "MONTHLY"
  | "QUARTERLY"
  | "YOY"
  | "PREV_QUARTER"
  | "CUSTOM";

// —— Server result & chart types ————————————————————————————————
type BundleMetric = "purchases" | "gmv" | "additions";
type PeriodWindow = "current" | "compare";
type GroupByKey = "connector" | "category";         // moved up so hooks can use it
type ChartMetric = "gmv" | "purchases";              // moved up so hooks can use it

type BundleRow = {
  period_window: PeriodWindow;
  level: number;
  connector_referral: string;
  global_connecta_id: string;
  category: string | null; // null for additions
  metric: BundleMetric;
  value: number;           // keep numeric for RPC; we still coerce with Number(...) defensively
};

// Only add if you will fetch from Supabase *in this file*
const supabase = typeof window !== "undefined"
  ? createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!)
  : null;

// Report metric selections
interface ReportParams {
  rootConnectorId: string;
  depth: 1 | 2 | 3 | 4 | 5;
  includeLevels: { L1: boolean; L2: boolean; L3: boolean; L4: boolean; L5: boolean };
  categories: Category[];
  metrics: {
    purchases: boolean;
    additions: boolean;
    wellnessScores: boolean;
    // Advanced
    activationRate: boolean;
    retention: boolean;
    streaks: boolean;
    dormancy: boolean;
    levelMix: boolean;
    leaderboards: boolean;
  };
  preset: TimePreset;
  customStart?: string; // ISO yyyy-mm-dd
  customEnd?: string;   // ISO yyyy-mm-dd
  groupBy: "LEVEL" | "PERIOD" | "CATEGORY" | "CONNECTOR";
  sortBy?: string;
  topN?: number;
  note?: string;
}

// Wellness row type
interface WellnessRow {
  id: string; // stable key
  sNo: number;
  activityName: string;
  durationMin: number | "";
  startTime: string; // HH:mm
  alarmOn: boolean;
  completed: boolean;
  passCode?: string;
  marksScored: number | ""; // awarded if completed (and pass code ok if set)
}

// —— Constants ——

const MESSAGE_COOLDOWN_MIN = 15; // client-side guard (server also enforces policies)

// Country/currency monthly threshold table (NOT exchange-rate normalized)
const THRESHOLDS_BY_CURRENCY: Record<
  string,
  { currency: string; monthlyThreshold: number; note?: string }
> = {
  INR: { currency: "INR", monthlyThreshold: 500000, note: "India base rule" },
  USD: { currency: "USD", monthlyThreshold: 100 },
  SAR: { currency: "SAR", monthlyThreshold: 300 },
  EUR: { currency: "EUR", monthlyThreshold: 100 },
};

// Dummy last-3-months earnings for UI preview (points or currency units — display as-is)
const MOCK_LAST3 = [
  { monthLabel: "2025-07", earned: 480000 },
  { monthLabel: "2025-08", earned: 520000 },
  { monthLabel: "2025-09", earned: 610000 },
];

const CATEGORIES: { key: Category; label: string }[] = [
  { key: "INDIVIDUAL", label: "Individual" },
  { key: "B2B", label: "B2B" },
  { key: "B2C", label: "B2C" },
  { key: "EXPORT", label: "Export" },
  { key: "IMPORT", label: "Import" },
];


// —— Utils ——

function cls(...parts: (string | false | null | undefined)[]) {
  return parts.filter(Boolean).join(" ");
}

function computeSplit(earned: number, threshold: number) {
  // R = min(E, T) + 0.5 * max(E - T, 0)
  // P = 0.5 * max(E - T, 0)
  const above = Math.max(earned - threshold, 0);
  const redeemable = Math.min(earned, threshold) + 0.5 * above;
  const promoCharity = 0.5 * above;
  return { redeemable, promoCharity };
}

function makeBlankWellnessRows(n = 10): WellnessRow[] {
  return Array.from({ length: n }).map((_, i) => ({
    id: `row-${i + 1}`,
    sNo: i + 1,
    activityName: "",
    durationMin: "",
    startTime: "06:00",
    alarmOn: false,
    completed: false,
    passCode: "",
    marksScored: "",
  }));
}

// —— Main Component ——

export default function AdminPanel({
  refCode,
  myGlobalId,
  country = "IN",
  state = "TN",
  currency = "INR",
}: Props) {
  const [sub, setSub] = useState<AdminSub>("reports");

  // simple cool-down tracker (per admin + audience hash)
  const canSendNow = (audHash: string) => {
    try {
      const key = `admin_msg_last_${audHash}`;
      const iso = localStorage.getItem(key);
      if (!iso) return true;
      const last = new Date(iso).getTime();
      const now = Date.now();
      const diffMin = (now - last) / 60000;
      return diffMin >= MESSAGE_COOLDOWN_MIN;
    } catch {
      return true;
    }
  };

  const markSentNow = (audHash: string) => {
    try {
      localStorage.setItem(`admin_msg_last_${audHash}`, new Date().toISOString());
    } catch {}
  };

  // —— REPORTS TAB STATE ——
  const [params, setParams] = useState<ReportParams>({
    rootConnectorId: myGlobalId || refCode || "",
    depth: 5,
    includeLevels: { L1: true, L2: true, L3: true, L4: true, L5: true },
    categories: ["INDIVIDUAL", "B2B", "B2C", "EXPORT", "IMPORT"],
    metrics: {
      purchases: true,
      additions: true,
      wellnessScores: true,
      activationRate: false,
      retention: false,
      streaks: false,
      dormancy: false,
      levelMix: false,
      leaderboards: false,
    },
    preset: "WEEKLY",
    groupBy: "LEVEL",
    sortBy: undefined,
    topN: 50,
    note: "",
  });

const [bundle, setBundle] = useState<BundleRow[] | null>(null);

// live data from Supabase (bundle compare)
const [loading, setLoading] = useState(false);
const [loadErr, setLoadErr] = useState<string | null>(null);
const [chartMetric, setChartMetric] = useState<ChartMetric>("gmv");
const [chartGroupBy, setChartGroupBy] = useState<GroupByKey>("connector");

// derive convenience slices for UI
const currentRows = useMemo(() => (bundle || []).filter(b => b.period_window === "current"), [bundle]);
const compareRows = useMemo(() => (bundle || []).filter(b => b.period_window === "compare"), [bundle]);

// Purchases (current): category != null and metric in purchases/gmv (we’ll pivot when rendering)
const purchaseRows = useMemo(
  () => currentRows.filter(r => r.category && (r.metric === "purchases" || r.metric === "gmv")),
  [currentRows]
);

// Additions (current): metric = 'additions' (category is null)
const additionsRows = useMemo(
  () => currentRows.filter(r => r.metric === "additions"),
  [currentRows]
);


// —— EDIT DETAILS TAB STATE — mirror Onboarding classifications —— 
type EditClassTab = "connectors" | "b2c" | "b2b" | "export" | "import";
const [editTab, setEditTab] = useState<EditClassTab>("connectors");


  useEffect(() => {
    if (sub === "edit") {
      document
        .querySelector("#edit-details-tabs")
        ?.scrollIntoView({ behavior: "smooth", block: "start" });
    }
  }, [sub]);

  // —— PROMOTIONS TAB STATE ——
  const threshold = THRESHOLDS_BY_CURRENCY[currency]?.monthlyThreshold ?? 500000; // fallback
  const promoCards = useMemo(() => {
    return MOCK_LAST3.map((m) => {
      const { redeemable, promoCharity } = computeSplit(m.earned, threshold);
      return { ...m, redeemable, promoCharity };
    });
  }, [threshold]);

  type Reason =
    | "MAX_QUAL_ADDS"
    | "HIGHEST_PURCHASE"
    | "BEST_WELLNESS"
    | "BEST_TIPS_LIKES"
    | "MEET_ATTENDANCE";

  const [bonus, setBonus] = useState({
    level: 1 as 1 | 2 | 3 | 4 | 5,
    periodPreset: "WEEKLY" as TimePreset,
    reason: "MAX_QUAL_ADDS" as Reason,
    prize1: 1000,
    prize2: 500,
    prize3: 250,
    previewWinners: [] as { place: 1 | 2 | 3; connectorId: string; metric: number }[],
    confirmation: "",
  });

  // —— FEEDBACK TAB STATE ——
  interface FeedbackItem {
    id: string;
    type: "wellness" | "business";
    url: string;
    title?: string;
    likes: number;
    liked?: boolean;
  }
  const [feedback, setFeedback] = useState<FeedbackItem[]>([]);
  const addFeedback = (type: "wellness" | "business", url: string) => {
    if (!url) return;
    setFeedback((prev) => [
      { id: `f-${Date.now()}`, type, url, title: undefined, likes: 0 },
      ...prev,
    ]);
  };
  const toggleLike = (id: string) => {
    setFeedback((prev) =>
      prev.map((f) =>
        f.id === id
          ? { ...f, liked: !f.liked, likes: f.liked ? f.likes - 1 : f.likes + 1 }
          : f
      )
    );
  };

  // —— WELLNESS TAB STATE ——
  const [wellnessRows, setWellnessRows] = useState<WellnessRow[]>(
    () => makeBlankWellnessRows(10)
  );

  const weeklyTotal = useMemo(
    () => wellnessRows.reduce((acc, r) => acc + (Number(r.marksScored) || 0), 0),
    [wellnessRows]
  );
  const monthlyTotal = weeklyTotal; // UI stub; real app will fetch server rollups

  const setRow = (i: number, patch: Partial<WellnessRow>) => {
    setWellnessRows((rows) =>
      rows.map((r, idx) => (idx === i ? { ...r, ...patch } : r))
    );
  };

async function runReport() {
  setLoading(true);
  setLoadErr(null);
  try {
    let rows: BundleRow[] | null = null;

    if (supabase) {
      const { data, error } = await supabase.rpc("rpc_report_bundle_compare", {
        p_root_ref: params.rootConnectorId,
        p_depth: params.depth,
        p_preset: params.preset,
        p_categories: params.categories, // ['INDIVIDUAL','B2B','B2C','EXPORT','IMPORT']
      });
      if (error) throw error;
      rows = (data ?? []) as BundleRow[];
    }

    // Fallback demo (only if RPC is unavailable or returned null)
    if (!rows || rows.length === 0) {
      rows = [
        {
          period_window: "current",
          level: 2,
          connector_referral: "India_Tamil Nadu_INTAAD000000003_G",
          global_connecta_id: "India_Tamil Nadu_INTAAD000000003_G",
          category: "INDIVIDUAL",
          metric: "gmv",
          value: 7056,
        },
        {
          period_window: "compare",
          level: 2,
          connector_referral: "India_Tamil Nadu_INTAAD000000003_G",
          global_connecta_id: "India_Tamil Nadu_INTAAD000000003_G",
          category: "INDIVIDUAL",
          metric: "gmv",
          value: 11109,
        },
        {
          period_window: "current",
          level: 1,
          connector_referral: "India_Tamil Nadu_INTAAC000000003_G",
          global_connecta_id: "India_Tamil Nadu_INTAAC000000003_G",
          category: null,
          metric: "purchases",
          value: 0,
        },
        {
          period_window: "compare",
          level: 1,
          connector_referral: "India_Tamil Nadu_INTAAC000000003_G",
          global_connecta_id: "India_Tamil Nadu_INTAAC000000003_G",
          category: null,
          metric: "purchases",
          value: 1,
        },
      ];
    }

    setBundle(rows);
  } catch (e: any) {
    setLoadErr(e?.message || "Fetch failed");
    setBundle(null);
  } finally {
    setLoading(false);
  }
}



function CompareChart({
  bundle,
  metric,
  groupBy,
  topN = 10,
}: {
  bundle: BundleRow[] | null;
  metric: ChartMetric;
  groupBy: GroupByKey;
  topN?: number;
}) {
  // prepare rows
  const rows = useMemo(() => bundle ?? [], [bundle]);

  // filter to only the metric we want (gmv or purchases). additions not charted here.
  const filtered = useMemo(
    () =>
      rows.filter(
        (r) =>
          (r.metric === "gmv" || r.metric === "purchases") &&
          r.metric === metric &&
          // if grouping by category, require a non-null category
          (groupBy === "category" ? r.category !== null : true) &&
          r.period_window !== undefined
      ),
    [rows, metric, groupBy]
  );

  // aggregate by chosen key → sum current & compare
  const data = useMemo(() => {
    const m = new Map<
      string,
      { key: string; current: number; compare: number }
    >();
    for (const r of filtered) {
      const key =
        groupBy === "connector"
          ? r.connector_referral
          : (r.category as string);
      if (!m.has(key)) m.set(key, { key, current: 0, compare: 0 });
      const slot = m.get(key)!;
      const val = Number(r.value) || 0;
      if (r.period_window === "current") slot.current += val;
      else if (r.period_window === "compare") slot.compare += val;
    }
    // sort by current desc & topN
    return Array.from(m.values())
      .sort((a, b) => b.current - a.current)
      .slice(0, topN);
  }, [filtered, groupBy, topN]);

  if (!rows.length) {
    return (
      <div className="text-xs text-gray-500">
        Run a report to see charts.
      </div>
    );
  }
  if (!data.length) {
    return (
      <div className="text-xs text-gray-500">
        No data for {metric.toUpperCase()} grouped by {groupBy}.
      </div>
    );
  }

  return (
    <div className="w-full h-80 rounded-md border p-2">
      <ResponsiveContainer width="100%" height="100%">
        <BarChart data={data} margin={{ top: 8, right: 16, left: 0, bottom: 8 }}>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis
            dataKey="key"
            tick={{ fontSize: 12 }}
            interval={0}
            angle={-20}
            textAnchor="end"
            height={50}
          />
          <YAxis tick={{ fontSize: 12 }} />
          <Tooltip />
          <Legend />
          <Bar dataKey="current" name="Current" />
          <Bar dataKey="compare" name="Compare" />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}


  // —— UI ——

  return (
    <div className="max-w-6xl mx-auto p-4">
      {/* Header keys */}
      <div className="mb-4 grid grid-cols-1 md:grid-cols-5 gap-2 text-sm">
        <KeyCard label="GLOBAL CONNECTA ID" value={myGlobalId || "—"} />
        <KeyCard label="REFERRAL CODE" value={refCode || "—"} />
        <KeyCard label="PRIMARY PHONE" value="+91-xxxxxxxxxx" />
        <KeyCard label="RECOVERY PHONE" value="+91-xxxxxxxxxx" />
        <KeyCard label="REGION" value={`${country}-${state}`} />
      </div>

      {/* Sub-tabs */}
      <div className="flex flex-wrap justify-center gap-2 mb-4">
        {[
          { k: "reports", l: "Custom Reports" },
          { k: "edit", l: "Edit Details" },
          { k: "promos", l: "Promotions" },
          { k: "feedback", l: "Feedback" },
          { k: "wellness", l: "Wellness" },
        ].map(({ k, l }) => (
          <button
            key={k}
            onClick={() => setSub(k as AdminSub)}
            className={cls(
              "px-4 py-2 rounded-full border text-sm",
              sub === (k as AdminSub)
                ? "bg-blue-600 text-white border-blue-600"
                : "bg-white"
            )}
          >
            {l}
          </button>
        ))}
      </div>

      {/* —— REPORTS —— */}
      {sub === "reports" && (
        <div className="rounded-md border p-3 space-y-3">
          <div className="text-sm text-gray-600">
            Build reports scoped to your tree (children up to 5 levels). Calendar
            week Mon–Sun. India time.
          </div>

          {/* Controls */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
            <div>
              <label className="block text-xs text-gray-600 mb-1">
                Root Connector ID
              </label>
              <input
                className="w-full border rounded-md p-2 text-sm"
                placeholder="e.g. IN_TN_AA001"
                value={params.rootConnectorId}
                onChange={(e) =>
                  setParams({ ...params, rootConnectorId: e.target.value })
                }
              />
            </div>
            <div>
              <label className="block text-xs text-gray-600 mb-1">
                Depth (levels)
              </label>
              <select
                className="w-full border rounded-md p-2 text-sm"
                value={params.depth}
                onChange={(e) =>
                  setParams({ ...params, depth: Number(e.target.value) as any })
                }
              >
                {[1, 2, 3, 4, 5].map((n) => (
                  <option key={n} value={n}>{`L${n}`}</option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-xs text-gray-600 mb-1">
                Levels included
              </label>
              <div className="flex gap-2 flex-wrap">
                {(Object.keys(params.includeLevels) as (
                  | "L1"
                  | "L2"
                  | "L3"
                  | "L4"
                  | "L5"
                )[]).map((k) => (
                  <label key={k} className="flex items-center gap-1 text-xs">
                    <input
                      type="checkbox"
                      checked={params.includeLevels[k]}
                      onChange={(e) =>
                        setParams({
                          ...params,
                          includeLevels: {
                            ...params.includeLevels,
                            [k]: e.target.checked,
                          },
                        })
                      }
                    />
                    <span>{k}</span>
                  </label>
                ))}
              </div>
            </div>

            {/* Categories */}
            <div className="md:col-span-3">
              <label className="block text-xs text-gray-600 mb-1">
                Categories
              </label>
              <div className="flex gap-2 flex-wrap text-xs">
                {CATEGORIES.map(({ key, label }) => (
                  <label key={key} className="flex items-center gap-1">
                    <input
                      type="checkbox"
                      checked={params.categories.includes(key)}
                      onChange={(e) =>
                        setParams({
                          ...params,
                          categories: e.target.checked
                            ? [...params.categories, key]
                            : params.categories.filter((c) => c !== key),
                        })
                      }
                    />
                    <span>{label}</span>
                  </label>
                ))}
              </div>
            </div>

            {/* Metrics */}
            <div className="md:col-span-3">
              <label className="block text-xs text-gray-600 mb-1">
                Metrics
              </label>
              <div className="grid grid-cols-2 md:grid-cols-3 gap-2 text-xs">
                {Object.entries(params.metrics).map(([k, v]) => (
                  <label key={k} className="flex items-center gap-1">
                    <input
                      type="checkbox"
                      checked={v as boolean}
                      onChange={(e) =>
                        setParams({
                          ...params,
                          metrics: { ...params.metrics, [k]: e.target.checked },
                        })
                      }
                    />
                    <span className="capitalize">
                      {k.replace(/([A-Z])/g, " $1").trim()}
                    </span>
                  </label>
                ))}
              </div>
              <div className="text-[11px] text-gray-500 mt-1">
                Advanced metrics appear below the main report as a separate
                section.
              </div>
            </div>

            {/* Time preset */}
            <div>
              <label className="block text-xs text-gray-600 mb-1">
                Time Window
              </label>
              <select
                className="w-full border rounded-md p-2 text-sm"
                value={params.preset}
                onChange={(e) =>
                  setParams({ ...params, preset: e.target.value as TimePreset })
                }
              >
                <option value="WEEKLY">Weekly (Mon–Sun)</option>
                <option value="FORTNIGHTLY">Fortnightly</option>
                <option value="MONTHLY">Monthly</option>
                <option value="QUARTERLY">Quarterly</option>
                <option value="YOY">YoY (same period last year)</option>
                <option value="PREV_QUARTER">Previous Quarter</option>
                <option value="CUSTOM">Custom</option>
              </select>
            </div>

            {params.preset === "CUSTOM" && (
              <div className="md:col-span-2 grid grid-cols-1 md:grid-cols-2 gap-2">
                <div>
                  <label className="block text-xs text-gray-600 mb-1">
                    Start
                  </label>
                  <input
                    type="date"
                    className="w-full border rounded-md p-2 text-sm"
                    value={params.customStart || ""}
                    onChange={(e) =>
                      setParams({ ...params, customStart: e.target.value })
                    }
                  />
                </div>
                <div>
                  <label className="block text-xs text-gray-600 mb-1">
                    End
                  </label>
                  <input
                    type="date"
                    className="w-full border rounded-md p-2 text-sm"
                    value={params.customEnd || ""}
                    onChange={(e) =>
                      setParams({ ...params, customEnd: e.target.value })
                    }
                  />
                </div>
              </div>
            )}

            {/* Grouping & sort */}
            <div>
              <label className="block text-xs text-gray-600 mb-1">
                Group By
              </label>
              <select
                className="w-full border rounded-md p-2 text-sm"
                value={params.groupBy}
                onChange={(e) =>
                  setParams({ ...params, groupBy: e.target.value as any })
                }
              >
                <option value="LEVEL">Level</option>
                <option value="PERIOD">Time Period</option>
                <option value="CATEGORY">Category</option>
                <option value="CONNECTOR">Connector</option>
              </select>
            </div>
            <div>
              <label className="block text-xs text-gray-600 mb-1">
                Sort By
              </label>
              <input
                className="w-full border rounded-md p-2 text-sm"
                placeholder="e.g. gmv desc"
                value={params.sortBy || ""}
                onChange={(e) =>
                  setParams({ ...params, sortBy: e.target.value })
                }
              />
            </div>
            <div>
              <label className="block text-xs text-gray-600 mb-1">Top N</label>
              <input
                type="number"
                min={1}
                className="w-full border rounded-md p-2 text-sm"
                value={params.topN || 50}
                onChange={(e) =>
                  setParams({ ...params, topN: Number(e.target.value) })
                }
              />
            </div>
          </div>

          {/* Action bar */}
          <div className="flex gap-2 flex-wrap items-center">
         <button
  className="px-4 py-2 rounded-md bg-blue-600 text-white disabled:opacity-60"
  onClick={runReport}
  disabled={loading}
>
  {loading ? "Running..." : "Run Report"}
</button>


{loadErr && <span className="text-red-600 text-sm">{loadErr}</span>}

            <button className="px-4 py-2 rounded-md border">Save Report</button>
            <button className="px-4 py-2 rounded-md border">Export CSV</button>
            <ShareAsNote
              audienceKey={`ref:${refCode || "na"}:levels:${Object.entries(
                params.includeLevels
              )
                .filter(([, v]) => v)
                .map(([k]) => k)
                .join("-")}`}
              canSendNow={canSendNow}
              onSent={markSentNow}
              cooldownMin={MESSAGE_COOLDOWN_MIN}
              defaultNote={params.note || ""}
            />
            <span className="text-[11px] text-gray-500">
              Sharing policy: Individuals — no limit; L1 weekly; L2 fortnightly;
              L3+ monthly (server-enforced).
            </span>
          </div>
          {/* —— Chart Controls —— */}
<div className="flex flex-wrap items-center gap-3 mt-2">
  <label className="text-sm text-gray-600">Chart metric:</label>
  <select
    className="border rounded-md p-1.5 text-sm"
    value={chartMetric}
    onChange={(e) => setChartMetric(e.target.value as ChartMetric)}
  >
    <option value="gmv">GMV</option>
    <option value="purchases">Purchases</option>
  </select>

  <label className="text-sm text-gray-600 ml-2">Group by:</label>
  <select
    className="border rounded-md p-1.5 text-sm"
    value={chartGroupBy}
    onChange={(e) => setChartGroupBy(e.target.value as GroupByKey)}
  >
    <option value="connector">Connector</option>
    <option value="category">Category</option>
  </select>
</div>

{/* —— Tiny Compare Chart —— */}
<div className="mt-2">
  <CompareChart
    bundle={bundle}
    metric={chartMetric}
    groupBy={chartGroupBy}
    topN={10}
  />
</div>


          {/* Table (Purchases current window) */}
<div className="overflow-auto rounded-md border">
  <table className="min-w-full text-sm">
    <thead className="bg-gray-50">
      <tr>
        <Th>Level</Th>
        <Th>Connector</Th>
        <Th>Category</Th>
        <Th className="text-right">Purchases</Th>
        <Th className="text-right">GMV</Th>
      </tr>
    </thead>
    <tbody>
      {(() => {
        // pivot purchases+gmv by (level, connector_referral, category)
        const key = (r: BundleRow) => `${r.level}|${r.connector_referral}|${r.category}`;
        const map = new Map<string, { level: number; connector: string; category: string; purchases?: number; gmv?: number }>();
        for (const r of purchaseRows) {
          const k = key(r);
          if (!map.has(k)) {
            map.set(k, {
              level: r.level,
              connector: r.connector_referral,
              category: r.category as string,
            });
          }
          const row = map.get(k)!;
          if (r.metric === "purchases") row.purchases = Number(r.value) || 0;
          if (r.metric === "gmv") row.gmv = Number(r.value) || 0;
        }
        const rows = Array.from(map.values());
        if (!rows.length && !loading) {
          return (
            <tr>
              <Td colSpan={5} className="text-center text-gray-500 py-6">
                No data — run a report or adjust filters.
              </Td>
            </tr>
          );
        }
        return rows.map((r, i) => (
          <tr key={i} className={i % 2 ? "bg-white" : "bg-gray-50/30"}>
            <Td>{`L${r.level}`}</Td>
            <Td className="font-mono">{r.connector}</Td>
            <Td>{r.category}</Td>
            <Td className="text-right">{r.purchases ?? 0}</Td>
            <Td className="text-right">{(r.gmv ?? 0).toLocaleString()}</Td>
          </tr>
        ));
      })()}
    </tbody>
  </table>
</div>

{/* Additions (current window) */}
<div className="overflow-auto rounded-md border mt-3">
  <table className="min-w-full text-sm">
    <thead className="bg-gray-50">
      <tr>
        <Th>Level</Th>
        <Th>Connector</Th>
        <Th className="text-right">New Additions</Th>
      </tr>
    </thead>
    <tbody>
      {(() => {
        // group additions by (level, connector)
        const key = (r: BundleRow) => `${r.level}|${r.connector_referral}`;
        const map = new Map<string, { level: number; connector: string; additions: number }>();
        for (const r of additionsRows) {
          const k = key(r);
          if (!map.has(k)) {
            map.set(k, { level: r.level, connector: r.connector_referral, additions: 0 });
          }
          const row = map.get(k)!;
          row.additions += Number(r.value) || 0;
        }
        const rows = Array.from(map.values());
        if (!rows.length && !loading) {
          return (
            <tr>
              <Td colSpan={3} className="text-center text-gray-500 py-6">
                No additions in current window.
              </Td>
            </tr>
          );
        }
        return rows.map((r, i) => (
          <tr key={i} className={i % 2 ? "bg-white" : "bg-gray-50/30"}>
            <Td>{`L${r.level}`}</Td>
            <Td className="font-mono">{r.connector}</Td>
            <Td className="text-right">{r.additions}</Td>
          </tr>
        ));
      })()}
    </tbody>
  </table>
</div>


          {/* Advanced metrics panel */}
          <div className="mt-4 p-3 rounded-md border bg-gray-50">
            <div className="text-xs font-semibold mb-2">Advanced Metrics</div>
            <ul className="text-xs list-disc pl-5 space-y-1">
              <li>
                Activation rate (new connectors with ≥ ₹5,000 purchase within 30
                days)
              </li>
              <li>Retention (≥1 purchase in each of last N months)</li>
              <li>Streaks (consecutive weeks with qualifying action)</li>
              <li>Dormancy (no purchase in last X days)</li>
              <li>Level contribution mix (% GMV by L1…L5)</li>
              <li>Leaderboards (GMV, new adds, wellness, likes)</li>
            </ul>
          </div>
        </div>
      )}

{/* —— EDIT DETAILS —— */}
{sub === "edit" && (
  <div className="rounded-md border p-3 space-y-4">
    {/* Header badges like onboarding */}
    <div className="flex flex-wrap gap-2 justify-center">
      <Badge label="PRIMARY PHONE" value="+91-xxxxxxxxxx" />
      <Badge label="RECOVERY PHONE" value="+91-xxxxxxxxxx" />
      <Badge
        label="LANGUAGE/COUNTRY/STATE"
        value={`Tamil (தமிழ்) — TA  |  ${country || "India"}  |  ${state || "Tamil Nadu"}`}
      />
    </div>

    {/* Classification tabs — same as onboarding */}
    <div id="edit-details-tabs" className="flex flex-wrap gap-3 justify-center">
      {([
        ["connectors", "Connectors"],
        ["b2c", "B2C Connectors"],
        ["b2b", "B2B Connectors"],
        ["export", "EXPORT Connectors"],
        ["import", "IMPORT Connectors"],
      ] as const).map(([k, label]) => (
        <button
          key={k}
          onClick={() => setEditTab(k)}
          className={`px-5 py-2 rounded-full border text-sm ${
            editTab === k ? "bg-blue-600 text-white border-blue-600" : "bg-gray-100"
          }`}
        >
          {label}
        </button>
      ))}
    </div>

    {/* Save classification */}
    <div className="flex items-center justify-center gap-2">
      <button
        className="px-4 py-2 rounded-md bg-blue-600 text-white"
        onClick={() => alert(`Saved classification: ${editTab.toUpperCase()} (stub)`)}
      >
        Save Classification
      </button>
      <span className="text-[11px] text-gray-500">
        Changing this switches the active details form below. (Persist via API later.)
      </span>
    </div>

    {/* CONNECTORS form (personal profile) */}
    {editTab === "connectors" && (
      <SectionCard title="Connectors — Profile">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          <TextField label="Full Name" placeholder="Your name" />
          <TextField label="Profession" placeholder="e.g. Doctor / Engineer" />
          <TextField label="Address Line - 1" className="md:col-span-2" />
          <TextField label="Address Line - 2" className="md:col-span-2" />
          <TextField label="Address Line - 3" className="md:col-span-2" />
          <TextField label="PIN / ZIP" />
          <TextField label="Email" placeholder="name@example.com" />
          <TextField label="Primary Phone" placeholder="+919876543210" />
          <TextField label="Recovery Phone" placeholder="+91987xxxxxxx" hint="Must differ from primary." />
        </div>
        <div className="mt-3">
          <button className="px-4 py-2 rounded-md bg-blue-600 text-white" onClick={() => alert("Profile saved (stub)")}>
            Save Profile
          </button>
        </div>
      </SectionCard>
    )}

    {/* B2C */}
    {editTab === "b2c" && (
      <SectionCard title="B2C Connectors — Business Details">
        <BusinessForm variant="b2c" />
      </SectionCard>
    )}

    {/* B2B */}
    {editTab === "b2b" && (
      <SectionCard title="B2B Connectors — Business Details">
        <BusinessForm variant="b2b" />
      </SectionCard>
    )}

    {/* EXPORT — placeholder fields; swap in your dedicated form later */}
    {editTab === "export" && (
      <SectionCard title="EXPORT Connectors — Details">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          <TextField label="IEC Number" placeholder="10-digit IEC" />
          <TextField label="Company Name" placeholder="Registered exporter name" />
          <TextField label="Primary HS Codes" placeholder="e.g. 8517, 9403, ..." className="md:col-span-2" />
          <TextField label="Target Countries" placeholder="e.g. UAE, USA, EU" className="md:col-span-2" />
          <TextField label="Preferred Port" placeholder="e.g. Chennai, Mundra" />
          <TextField label="Logistics Partner" placeholder="e.g. DHL / Maersk" />
          <TextField label="Website / Social" placeholder="https://..." className="md:col-span-2" />
        </div>
        <div className="mt-3">
          <button className="px-4 py-2 rounded-md bg-blue-600 text-white" onClick={() => alert("EXPORT details saved (stub)")}>
            Save EXPORT Details
          </button>
        </div>
      </SectionCard>
    )}

    {/* IMPORT — placeholder fields */}
    {editTab === "import" && (
      <SectionCard title="IMPORT Connectors — Details">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          <TextField label="Importer Reg. / IEC" placeholder="IEC / UIN" />
          <TextField label="Company Name" placeholder="Registered importer name" />
          <TextField label="Source Countries" placeholder="e.g. China, Vietnam" className="md:col-span-2" />
          <TextField label="Main HS Codes" placeholder="e.g. 8708, 7308" className="md:col-span-2" />
          <TextField label="Customs Broker" placeholder="CHA name" />
          <TextField label="Warehousing Location" placeholder="City / PIN" />
          <TextField label="Website / Social" placeholder="https://..." className="md:col-span-2" />
        </div>
        <div className="mt-3">
          <button className="px-4 py-2 rounded-md bg-blue-600 text-white" onClick={() => alert("IMPORT details saved (stub)")}>
            Save IMPORT Details
          </button>
        </div>
      </SectionCard>
    )}
  </div>
)}


      {/* —— PROMOTIONS —— */}
      {sub === "promos" && (
        <div className="rounded-md border p-3 space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
            {promoCards.map((c) => (
              <div key={c.monthLabel} className="rounded-lg border p-3">
                <div className="text-xs text-gray-500">Month</div>
                <div className="text-sm font-medium">{c.monthLabel}</div>
                <div className="mt-2 text-xs">Earned</div>
                <div className="text-lg font-semibold">
                  {c.earned.toLocaleString()} {currency}
                </div>
                <div className="mt-2 text-xs">Redeemable</div>
                <div className="text-lg">
                  {Math.round(c.redeemable).toLocaleString()} {currency}
                </div>
                <div className="mt-2 text-xs">Promo/Charity Pool</div>
                <div className="text-lg">
                  {Math.round(c.promoCharity).toLocaleString()} {currency}
                </div>
              </div>
            ))}
          </div>

          <div className="rounded-md border p-3">
            <div className="text-xs text-gray-500 mb-2">
              Monthly thresholds by currency (NOT FX equivalents)
            </div>
            <div className="overflow-auto">
              <table className="min-w-[400px] text-sm">
                <thead>
                  <tr className="bg-gray-50">
                    <Th>Currency</Th>
                    <Th className="text-right">Monthly Threshold</Th>
                    <Th>Note</Th>
                  </tr>
                </thead>
                <tbody>
                  {Object.values(THRESHOLDS_BY_CURRENCY).map((t) => (
                    <tr key={t.currency}>
                      <Td>{t.currency}</Td>
                      <Td className="text-right">
                        {t.monthlyThreshold.toLocaleString()}
                      </Td>
                      <Td>{t.note || ""}</Td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Bonus generator */}
          <SectionCard title="Promotion Bonus Generator">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
              <div>
                <label className="block text-xs text-gray-600 mb-1">
                  Target Level
                </label>
                <select
                  className="w-full border rounded-md p-2 text-sm"
                  value={bonus.level}
                  onChange={(e) =>
                    setBonus({ ...bonus, level: Number(e.target.value) as any })
                  }
                >
                  {[1, 2, 3, 4, 5].map((n) => (
                    <option key={n} value={n}>{`L${n}`}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-xs text-gray-600 mb-1">
                  Period
                </label>
                <select
                  className="w-full border rounded-md p-2 text-sm"
                  value={bonus.periodPreset}
                  onChange={(e) =>
                    setBonus({
                      ...bonus,
                      periodPreset: e.target.value as TimePreset,
                    })
                  }
                >
                  <option value="WEEKLY">Weekly</option>
                  <option value="FORTNIGHTLY">Fortnightly</option>
                  <option value="MONTHLY">Monthly</option>
                </select>
              </div>
              <div>
                <label className="block text-xs text-gray-600 mb-1">
                  Reason
                </label>
                <select
                  className="w-full border rounded-md p-2 text-sm"
                  value={bonus.reason}
                  onChange={(e) =>
                    setBonus({ ...bonus, reason: e.target.value as any })
                  }
                >
                  <option value="MAX_QUAL_ADDS">
                    Most new connectors (≥ ₹5k purchasers)
                  </option>
                  <option value="HIGHEST_PURCHASE">
                    Highest purchase in level
                  </option>
                  <option value="BEST_WELLNESS">Most wellness points</option>
                  <option value="BEST_TIPS_LIKES">Best tips (likes)</option>
                  <option value="MEET_ATTENDANCE">
                    Full Google Meet attendance
                  </option>
                </select>
              </div>

              <NumberField
                label="1st Prize"
                value={bonus.prize1}
                onChange={(v) => setBonus({ ...bonus, prize1: v })}
              />
              <NumberField
                label="2nd Prize"
                value={bonus.prize2}
                onChange={(v) => setBonus({ ...bonus, prize2: v })}
              />
              <NumberField
                label="3rd Prize"
                value={bonus.prize3}
                onChange={(v) => setBonus({ ...bonus, prize3: v })}
              />
            </div>

            <div className="flex gap-2 mt-2">
              <button
                className="px-4 py-2 rounded-md border"
                onClick={() =>
                  setBonus({
                    ...bonus,
                    previewWinners: [
                      { place: 1, connectorId: "IN_TN_AB001", metric: 12 },
                      { place: 2, connectorId: "IN_TN_AB023", metric: 9 },
                      { place: 3, connectorId: "IN_TN_AB101", metric: 7 },
                    ],
                  })
                }
              >
                Preview Winners
              </button>
              <button
                className="px-4 py-2 rounded-md bg-blue-600 text-white"
                onClick={() =>
                  alert(
                    "Promotion created (stub). Points deducted from Promo/Charity pool."
                  )
                }
              >
                Create Promotion
              </button>
            </div>
            {/* Quick compare summary (optional) */}
{bundle && (
  <div className="text-xs text-gray-600">
    Showing <b>current</b> window. You have <b>{compareRows.length}</b> compare rows available for charts/deltas.
  </div>
)}
       
            {bonus.previewWinners.length > 0 && (
              <div className="mt-3 overflow-auto rounded-md border">
                <table className="min-w-[400px] text-sm">
                  <thead className="bg-gray-50">
                    <tr>
                      <Th>Place</Th>
                      <Th>Connector</Th>
                      <Th className="text-right">Metric</Th>
                    </tr>
                  </thead>
                  <tbody>
                    {bonus.previewWinners.map((w) => (
                      <tr key={w.place}>
                        <Td>{w.place}</Td>
                        <Td className="font-mono">{w.connectorId}</Td>
                        <Td className="text-right">{w.metric}</Td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                <div className="text-[11px] text-gray-500 p-2">
                  Tie-break rule: One bonus per connector per selected period. If
                  multiple criteria tie, earlier timestamp wins (server-enforced).
                </div>
              </div>
            )}
          </SectionCard>

          {/* Charity tracker */}
          <SectionCard title="Charity & Rotary">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              <TextField label="Rotary Club" placeholder="Rotary Coimbatore Central" />
              <NumberField label="Joining Fees (from Pool)" value={0} onChange={() => {}} />
              <NumberField label="Monthly Subscription (from Pool)" value={0} onChange={() => {}} />
            </div>
          </SectionCard>
        </div>
      )}

      {/* —— FEEDBACK —— */}
      {sub === "feedback" && (
        <div className="rounded-md border p-3 space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            <UrlAdder
              label="Add Wellness Feedback (YouTube/Instagram)"
              onAdd={(url) => addFeedback("wellness", url)}
            />
            <UrlAdder
              label="Add Business Tips (YouTube/Instagram)"
              onAdd={(url) => addFeedback("business", url)}
            />
          </div>

          <div className="rounded-md border overflow-hidden">
            <table className="min-w-full text-sm">
              <thead className="bg-gray-50">
                <tr>
                  <Th>Type</Th>
                  <Th>URL</Th>
                  <Th className="text-right">Likes</Th>
                  <Th></Th>
                </tr>
              </thead>
              <tbody>
                {feedback.map((f) => (
                  <tr key={f.id}>
                    <Td className="capitalize">{f.type}</Td>
                    <Td className="truncate max-w-[420px]">
                      <a
                        className="text-blue-600 underline"
                        href={f.url}
                        target="_blank"
                        rel="noreferrer"
                      >
                        {f.url}
                      </a>
                    </Td>
                    <Td className="text-right">{f.likes}</Td>
                    <Td className="text-right">
                      <button
                        className={cls(
                          "px-3 py-1.5 rounded border",
                          f.liked
                            ? "bg-blue-600 text-white border-blue-600"
                            : "bg-white"
                        )}
                        onClick={() => toggleLike(f.id)}
                      >
                        {f.liked ? "Liked" : "Like"}
                      </button>
                    </Td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="text-[11px] text-gray-500">
            “Best tips (likes)” promotion reason uses in-app likes only (deduped
            per viewer).
          </div>
        </div>
      )}

      {/* —— WELLNESS —— */}
      {sub === "wellness" && (
        <div className="rounded-md border p-3 space-y-3">
          <div className="text-sm text-gray-600 mb-1">
            Configure up to 50 activities. Passcode optional; if set, completion
            requires correct code.
          </div>
          <div className="overflow-auto rounded-md border">
            <table className="min-w-[900px] text-sm">
              <thead className="bg-gray-50">
                <tr>
                  <Th className="w-14">S. No</Th>
                  <Th>Name of Activity</Th>
                  <Th className="w-40">Duration (min)</Th>
                  <Th className="w-40">Start Time</Th>
                  <Th className="w-36">Set Alarm</Th>
                  <Th className="w-40">Completed</Th>
                  <Th className="w-40">Pass Code</Th>
                  <Th className="w-36 text-right">Marks Scored</Th>
                  <Th className="w-40 text-right">UpToDate (Week)</Th>
                  <Th className="w-40 text-right">UpToDate (Month)</Th>
                </tr>
              </thead>
              <tbody>
                {wellnessRows.map((r, idx) => (
                  <tr
                    key={r.id}
                    className={idx % 2 ? "bg-white" : "bg-gray-50/30"}
                  >
                    <Td>{r.sNo}</Td>
                    <Td>
                      <input
                        className="w-full border rounded-md p-1"
                        value={r.activityName}
                        onChange={(e) =>
                          setRow(idx, { activityName: e.target.value })
                        }
                      />
                    </Td>
                    <Td>
                      <input
                        type="number"
                        min={0}
                        className="w-full border rounded-md p-1"
                        value={r.durationMin}
                        onChange={(e) =>
                          setRow(idx, {
                            durationMin:
                              e.target.value === "" ? "" : Number(e.target.value),
                          })
                        }
                      />
                    </Td>
                    <Td>
                      <input
                        type="time"
                        className="w-full border rounded-md p-1"
                        value={r.startTime}
                        onChange={(e) => setRow(idx, { startTime: e.target.value })}
                      />
                    </Td>
                    <Td>
                      <label className="inline-flex items-center gap-2">
                        <input
                          type="checkbox"
                          checked={r.alarmOn}
                          onChange={(e) => setRow(idx, { alarmOn: e.target.checked })}
                        />
                        <span className="text-xs">On</span>
                      </label>
                    </Td>
                    <Td>
                      <label className="inline-flex items-center gap-2">
                        <input
                          type="checkbox"
                          checked={r.completed}
                          onChange={(e) => setRow(idx, { completed: e.target.checked })}
                        />
                        <span className="text-xs">Yes</span>
                      </label>
                    </Td>
                    <Td>
                      <input
                        className="w-full border rounded-md p-1"
                        value={r.passCode || ""}
                        onChange={(e) => setRow(idx, { passCode: e.target.value })}
                        placeholder="optional"
                      />
                    </Td>
                    <Td className="text-right">
                      <input
                        type="number"
                        min={0}
                        className="w-full border rounded-md p-1 text-right"
                        value={r.marksScored}
                        onChange={(e) =>
                          setRow(idx, {
                            marksScored:
                              e.target.value === "" ? "" : Number(e.target.value),
                          })
                        }
                      />
                    </Td>
                    <Td className="text-right">{weeklyTotal}</Td>
                    <Td className="text-right">{monthlyTotal}</Td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="flex gap-2">
            <button
              className="px-4 py-2 rounded-md border"
              onClick={() =>
                setWellnessRows((r) =>
                  r.length >= 50
                    ? r
                    : [
                        ...r,
                        {
                          ...makeBlankWellnessRows(1)[0],
                          sNo: r.length + 1,
                          id: `row-${r.length + 1}`,
                        },
                      ]
                )
              }
            >
              Add Row
            </button>
            <button
              className="px-4 py-2 rounded-md border"
              onClick={() => setWellnessRows(makeBlankWellnessRows(10))}
            >
              Reset Template
            </button>
            <button
              className="px-4 py-2 rounded-md bg-blue-600 text-white"
              onClick={() => alert("Wellness template saved (stub)")}
            >
              Save Template
            </button>
          </div>
        </div>
      )}
    </div>
  ); // <- closes return
} // <- closes component

// —— Small UI helpers ——

function KeyCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-md border p-2">
      <div className="text-[11px] text-gray-500">{label}</div>
      <div className="text-sm font-medium truncate">{value}</div>
    </div>
  );
}
function Badge({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-md border px-3 py-1.5 text-xs bg-white shadow-sm">
      <div className="text-[10px] text-gray-500">{label}</div>
      <div className="font-medium">{value}</div>
    </div>
  );
}

function Th({
  children,
  className = "",
}: React.PropsWithChildren<{ className?: string }>) {
  return (
    <th className={cls("text-left px-2 py-2 font-semibold text-gray-700", className)}>
      {children}
    </th>
  );
}

function Td({
  children,
  className = "",
}: React.PropsWithChildren<{ className?: string }>) {
  return <td className={cls("px-2 py-2", className)}>{children}</td>;
}

function SectionCard({
  title,
  children,
}: React.PropsWithChildren<{ title: string }>) {
  return (
    <div className="rounded-md border p-3">
      <div className="text-sm font-semibold mb-2">{title}</div>
      {children}
    </div>
  );
}

function TextField(
  {
    label,
    hint,
    className,
    ...rest
  }: React.InputHTMLAttributes<HTMLInputElement> & { label: string; hint?: string }
) {
  return (
    <div className={cls("", className)}>
      <label className="block text-xs text-gray-600 mb-1">{label}</label>
      <input
        {...rest}
        className={cls("w-full border rounded-md p-2 text-sm", (rest.className as string) || "")}
      />
      {hint && <div className="text-[11px] text-gray-500 mt-1">{hint}</div>}
    </div>
  );
}

function NumberField({
  label,
  value,
  onChange,
}: {
  label: string;
  value: number;
  onChange: (v: number) => void;
}) {
  return (
    <div>
      <label className="block text-xs text-gray-600 mb-1">{label}</label>
      <input
        type="number"
        className="w-full border rounded-md p-2 text-sm"
        value={value}
        onChange={(e) => onChange(Number(e.target.value))}
      />
    </div>
  );
}

function ToggleField({ label }: { label: string }) {
  const [val, setVal] = useState(false);
  return (
    <label className="inline-flex items-center gap-2">
      <input type="checkbox" checked={val} onChange={(e) => setVal(e.target.checked)} />
      <span className="text-sm">{label}</span>
    </label>
  );
}

function UrlAdder({ label, onAdd }: { label: string; onAdd: (url: string) => void }) {
  const [url, setUrl] = useState("");
  return (
    <div>
      <label className="block text-xs text-gray-600 mb-1">{label}</label>
      <div className="flex gap-2">
        <input
          className="flex-1 border rounded-md p-2 text-sm"
          placeholder="https://youtu.be/... or https://instagram.com/..."
          value={url}
          onChange={(e) => setUrl(e.target.value)}
        />
        <button
          className="px-4 py-2 rounded-md border"
          onClick={() => {
            onAdd(url.trim());
            setUrl("");
          }}
        >
          Add
        </button>
      </div>
    </div>
  );
}

function ShareAsNote({
  audienceKey,
  canSendNow,
  onSent,
  cooldownMin,
  defaultNote,
}: {
  audienceKey: string;
  canSendNow: (k: string) => boolean;
  onSent: (k: string) => void;
  cooldownMin: number;
  defaultNote: string;
}) {
  const [note, setNote] = useState(defaultNote);
  const [busy, setBusy] = useState(false);
  const allowed = canSendNow(audienceKey);
  return (
    <div className="flex items-center gap-2">
      <input
        className="border rounded-md p-2 text-sm w-64"
        placeholder="Short note to attach"
        value={note}
        onChange={(e) => setNote(e.target.value)}
      />
      <button
        disabled={!allowed || busy}
        title={!allowed ? `Please wait ${cooldownMin} minutes between sends` : ""}
        className={cls("px-4 py-2 rounded-md", !allowed || busy ? "bg-gray-300" : "bg-emerald-600 text-white")}
        onClick={async () => {
          setBusy(true);
          try {
            // later: POST /reports/share-note
            await new Promise((r) => setTimeout(r, 600));
            onSent(audienceKey);
            alert("Report note sent (stub). Server will enforce audience limits.");
          } finally {
            setBusy(false);
          }
        }}
      >
        Share as Note
      </button>
    </div>
  );
}
