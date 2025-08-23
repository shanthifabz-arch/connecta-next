"use client";

import { useEffect, useMemo, useState } from "react";
import { supabase } from "@/lib/supabaseClient";

/** ---------- Types ---------- */
export interface CountryStateRow {
  country: string;
  states?: string[] | string | null; // supports JSON array, CSV string, or mixed objects
  // Optional columns you may add later without breaking anything:
  // country_code?: string | null;
}

type StatesByCountry = Record<string, string[]>;

/** ---------- Local cache config ---------- */
const LS_KEY = "connecta_country_states_v2";
const LS_TS_KEY = "connecta_country_states_v2_ts";
const CACHE_TTL_MS = 7 * 24 * 60 * 60 * 1000; // 7 days (stale-while-revalidate)

/** ---------- Helpers ---------- */
function toArrayStates(input: CountryStateRow["states"]): string[] {
  if (!input) return [];

  // 1) If it's already an array, normalize each entry
  if (Array.isArray(input)) {
    const normalized = input
      .flatMap((item) => {
        if (typeof item === "string") return item;
        if (typeof item === "number") return String(item);
        if (Array.isArray(item)) return item.map((x) => String(x));
        if (item && typeof item === "object") {
          // Common shapes: { name: "Dhaka" }, { state: "Dhaka" }, { label: "Dhaka" }, etc.
          const candidate =
            (item as any).name ??
            (item as any).state ??
            (item as any).State ??
            (item as any).district ??
            (item as any).province ??
            (item as any).region ??
            (item as any).label ??
            (item as any).value ??
            null;
          if (typeof candidate === "string") return candidate;
        }
        return null;
      })
      .filter((s): s is string => !!s);
    return normalized;
  }

  // 2) If it's a string, try JSON first (in case it's a JSON-encoded array)
  if (typeof input === "string") {
    const str = input.trim();
    if (str.startsWith("[") || str.startsWith("{")) {
      try {
        const parsed = JSON.parse(str);
        return toArrayStates(parsed as any);
      } catch {
        // fall through to CSV parsing
      }
    }
    // CSV / delimited string (support commas, semicolons, pipes, or newlines)
    return str
      .split(/[,\n;|]/g)
      .map((s) => s.trim())
      .filter(Boolean);
  }

  // 3) Number or unexpected
  if (typeof input === "number") return [String(input)];

  return [];
}

function dedupeAndSort(list: string[]): string[] {
  // Coerce to string safely, trim, collapse inner whitespace
  const cleaned = list
    .map((s) => (typeof s === "string" ? s : String(s)))
    .map((s) => s.replace(/\s+/g, " ").trim())
    .filter(Boolean);

  return Array.from(new Set(cleaned)).sort((a, b) =>
    a.localeCompare(b, undefined, { sensitivity: "base" })
  );
}

function normalizeRows(rows: CountryStateRow[]): { countries: string[]; statesByCountry: StatesByCountry } {
  const map: Record<string, string[]> = {};

  for (const row of rows) {
    const country = (row.country || "").trim();
    if (!country) continue;

    const lc = country.toLowerCase();
    const existing = map[lc] ?? [];
    const incoming = toArrayStates(row.states);

    map[lc] = dedupeAndSort([...existing, ...incoming]);
  }

  // Build stable, case-preserving country names (prefer first encountered casing)
  const displayCaseMap = new Map<string, string>();
  for (const row of rows) {
    const name = (row.country || "").trim();
    if (!name) continue;
    const lc = name.toLowerCase();
    if (!displayCaseMap.has(lc)) displayCaseMap.set(lc, name);
  }

  const countries = Object.keys(map)
    .map((lc) => displayCaseMap.get(lc) || lc)
    .sort((a, b) => a.localeCompare(b, undefined, { sensitivity: "base" }));

  // Remap to display-case keys
  const statesByCountry: StatesByCountry = {};
  for (const lc of Object.keys(map)) {
    const proper = displayCaseMap.get(lc) || lc;
    statesByCountry[proper] = map[lc];
  }

  return { countries, statesByCountry };
}

function loadFromCache():
  | { countries: string[]; statesByCountry: StatesByCountry }
  | null {
  try {
    if (typeof window === "undefined") return null;
    const raw = localStorage.getItem(LS_KEY);
    const ts = localStorage.getItem(LS_TS_KEY);
    if (!raw || !ts) return null;

    // Stale-while-revalidate: we still show even if TTL passed; fetch will revalidate
    const parsed = JSON.parse(raw) as { countries: string[]; statesByCountry: StatesByCountry };
    if (!parsed || !Array.isArray(parsed.countries) || typeof parsed.statesByCountry !== "object") return null;
    return parsed;
  } catch {
    return null;
  }
}

function saveToCache(payload: { countries: string[]; statesByCountry: StatesByCountry }) {
  try {
    if (typeof window === "undefined") return;
    localStorage.setItem(LS_KEY, JSON.stringify(payload));
    localStorage.setItem(LS_TS_KEY, String(Date.now()));
  } catch {
    // ignore storage quota / privacy mode errors
  }
}

/** ---------- Hook ---------- */
export function useCountryStateOptions() {
  const [countries, setCountries] = useState<string[]>([]);
  const [statesByCountry, setStatesByCountry] = useState<StatesByCountry>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Serve cache immediately if available (SWR-style)
  useEffect(() => {
    const cached = loadFromCache();
    if (cached) {
      setCountries(cached.countries);
      setStatesByCountry(cached.statesByCountry);
      setLoading(false); // UI stays responsive while we revalidate
    }
  }, []);

  const fetchFromSupabase = async () => {
    try {
      const { data, error } = await supabase
        .from<CountryStateRow>("country_states")
        .select("country, states")
        .order("country", { ascending: true });

      // Some environments may return `error = {}`; treat as non-error unless it has a message
      const isRealError = !!(error && (error as any).message);

      if (isRealError) {
        console.error("[useCountryStateOptions] Supabase error:", error);
        setError((error as any).message || "Failed to load country/state data");
        setLoading(false);
        return;
      }

      const rows = Array.isArray(data) ? data : [];
      const normalized = normalizeRows(rows);

      // Fallback if table is empty (keeps app usable)
      if (!normalized.countries.length) {
        const fallback = { countries: ["India"], statesByCountry: { India: [] } };
        setCountries(fallback.countries);
        setStatesByCountry(fallback.statesByCountry);
        saveToCache(fallback);
        setError(null);
        setLoading(false);
        return;
      }

      setCountries(normalized.countries);
      setStatesByCountry(normalized.statesByCountry);
      saveToCache(normalized);
      setError(null);
      setLoading(false);
    } catch (e: any) {
      console.error("[useCountryStateOptions] unexpected error:", e);
      setError(e?.message || "Unexpected error");
      setLoading(false);
    }
  };

  // Initial fetch (revalidate even if cache was shown)
  useEffect(() => {
    fetchFromSupabase();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  /** Manual refresh if needed */
  const refresh = () => {
    setLoading(true);
    fetchFromSupabase();
  };

  /** Convenience: get states for a given country (case-insensitive) */
  const getStatesFor = useMemo(
    () => (countryName: string | null | undefined): string[] => {
      if (!countryName) return [];
      // Direct match
      if (statesByCountry[countryName]) return statesByCountry[countryName];
      // Case-insensitive match
      const key = Object.keys(statesByCountry).find(
        (k) => k.toLowerCase() === countryName.toLowerCase()
      );
      return key ? statesByCountry[key] : [];
    },
    [statesByCountry]
  );

  return { countries, statesByCountry, loading, error, refresh, getStatesFor };
}
