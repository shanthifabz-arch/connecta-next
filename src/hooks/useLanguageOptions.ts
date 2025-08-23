"use client";

import { useEffect, useMemo, useState } from "react";
import { supabase } from "@/lib/supabaseClient";

/** ---------- Types ---------- */
export type LanguageRow = {
  language_code: string;          // e.g., "en", "ta", "bn-BD"
  language_iso_code?: string | null;
  display_name?: string | null;   // UI-friendly name in English
  label_native?: string | null;   // Native script name
  emoji_flag?: string | null;     // Optional flag emoji
  // NOTE: Your table does NOT have enabled/country_code — we won't select them.
};

export type LanguageOption = {
  language_code: string;
  language_iso_code?: string | null;
  display_name: string;
  label_native?: string | null;
  emoji_flag?: string | null;

  /** Aliases kept for backward compatibility with existing code */
  label: string;  // mirrors display_name (or best fallback)
  code: string;   // mirrors language_code
};

/** ---------- Local cache config ---------- */
const LS_KEY = "connecta_language_options_v3";
const LS_TS_KEY = "connecta_language_options_v3_ts";

/** ---------- Helpers ---------- */
function normalizeRow(row: LanguageRow): LanguageOption {
  const display =
    (row.display_name && row.display_name.trim()) ||
    (row.label_native && row.label_native.trim()) ||
    (row.language_code && row.language_code.trim()) ||
    "English";

  const language_code = (row.language_code || "en").trim();

  return {
    language_code,
    language_iso_code: row.language_iso_code ?? null,
    display_name: display,
    label_native: row.label_native ?? null,
    emoji_flag: row.emoji_flag ?? null,
    // aliases for backward compatibility
    label: display,
    code: language_code,
  };
}

function stableSort(items: LanguageOption[]): LanguageOption[] {
  return [...items].sort((a, b) => {
    const aKey =
      (a.display_name || "").toLowerCase() ||
      (a.label_native || "").toLowerCase() ||
      a.language_code.toLowerCase();
    const bKey =
      (b.display_name || "").toLowerCase() ||
      (b.label_native || "").toLowerCase() ||
      b.language_code.toLowerCase();
    if (aKey < bKey) return -1;
    if (aKey > bKey) return 1;
    return 0;
  });
}

function loadFromCache(): LanguageOption[] | null {
  try {
    if (typeof window === "undefined") return null;
    const raw = localStorage.getItem(LS_KEY);
    const ts = localStorage.getItem(LS_TS_KEY);
    if (!raw || !ts) return null;
    const parsed = JSON.parse(raw) as LanguageOption[];
    return Array.isArray(parsed) ? parsed : null;
  } catch {
    return null;
  }
}

function saveToCache(items: LanguageOption[]) {
  try {
    if (typeof window === "undefined") return;
    localStorage.setItem(LS_KEY, JSON.stringify(items));
    localStorage.setItem(LS_TS_KEY, String(Date.now()));
  } catch {
    // ignore quota / privacy mode issues
  }
}

function hasMeaningfulError(err: any): boolean {
  if (!err) return false;
  if (typeof err !== "object") return true;
  const msg = (err.message || err.code || err.details || err.hint || "").trim?.() || "";
  return msg.length > 0;
}

function summarizeError(err: any): string {
  if (!err) return "unknown";
  if (typeof err === "string") return err;
  return (err.message || err.code || err.details || err.hint || "unknown").toString();
}

/** ---------- Hook ---------- */
export function useLanguageOptions() {
  const [languageOptions, setLanguageOptions] = useState<LanguageOption[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Show cached immediately if present (SWR: stale-while-revalidate)
  useEffect(() => {
    const cached = loadFromCache();
    if (cached && cached.length) {
      setLanguageOptions(cached);
      setLoading(false);
    }
  }, []);

  const fetchFromSupabase = async () => {
    try {
      // Query ONLY columns that exist in your schema (per your SQL output)
      const { data, error } = await supabase
        .from("translations")
        .select("language_code, language_iso_code, display_name, label_native, emoji_flag");

      if (hasMeaningfulError(error)) {
        if (process.env.NODE_ENV !== "production") {
          console.warn("[useLanguageOptions] translations warning:", summarizeError(error));
        }
        // keep UI usable with a safe fallback
        setLanguageOptions((prev) =>
          prev.length
            ? prev
            : [
                {
                  language_code: "en",
                  language_iso_code: "en",
                  display_name: "English",
                  label_native: "English",
                  emoji_flag: "🌐",
                  label: "English",
                  code: "en",
                },
              ]
        );
        setError(summarizeError(error));
        setLoading(false);
        return;
      }

      const rows = Array.isArray(data) ? data : [];
      const normalized = stableSort(rows.map(normalizeRow));

      if (normalized.length === 0) {
        const fallback: LanguageOption[] = [
          {
            language_code: "en",
            language_iso_code: "en",
            display_name: "English",
            label_native: "English",
            emoji_flag: "🌐",
            label: "English",
            code: "en",
          },
        ];
        setLanguageOptions(fallback);
        saveToCache(fallback);
        setError(null);
        setLoading(false);
        return;
      }

      setLanguageOptions(normalized);
      saveToCache(normalized);
      setError(null);
      setLoading(false);
    } catch (e: any) {
      if (process.env.NODE_ENV !== "production") {
        console.warn("[useLanguageOptions] unexpected warning:", summarizeError(e));
      }
      setError(e?.message || "Unexpected error");
      setLanguageOptions((prev) =>
        prev.length
          ? prev
          : [
              {
                language_code: "en",
                language_iso_code: "en",
                display_name: "English",
                label_native: "English",
                emoji_flag: "🌐",
                label: "English",
                code: "en",
              },
            ]
      );
      setLoading(false);
    }
  };

  // Initial fetch (and revalidate even if cache was shown)
  useEffect(() => {
    fetchFromSupabase();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  /** Manual refresh if needed */
  const refresh = () => {
    setLoading(true);
    fetchFromSupabase();
  };

  /** Convenience maps derived from current options (no breaking change) */
  const nameToCodeMap = useMemo(() => {
    const map = new Map<string, string>();
    for (const item of languageOptions) {
      if (item.display_name) map.set(item.display_name.toLowerCase(), item.language_code);
      if (item.label_native) map.set(item.label_native.toLowerCase(), item.language_code);
      map.set(item.language_code.toLowerCase(), item.language_code);
      // support "tamil" -> "ta" even without spaces
      if (item.display_name) map.set(item.display_name.replace(/\s+/g, "").toLowerCase(), item.language_code);
      if (item.label_native) map.set(item.label_native.replace(/\s+/g, "").toLowerCase(), item.language_code);
    }
    return map;
  }, [languageOptions]);

  const codeToNameMap = useMemo(() => {
    const map = new Map<string, string>();
    for (const item of languageOptions) {
      map.set(item.language_code, item.display_name || item.label || item.language_code);
    }
    return map;
  }, [languageOptions]);

  return {
    languageOptions,
    loading,
    error,
    refresh,
    nameToCodeMap,
    codeToNameMap,
  };
}
