"use client";

import { useEffect, useState } from "react";
import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;
const supabase = createClient(supabaseUrl, supabaseAnonKey);

type TranslationsMap = Record<string, string>;

export function useCachedTranslations(languageCode: string): TranslationsMap {
  const [translations, setTranslations] = useState<TranslationsMap>({});

  useEffect(() => {
    if (!languageCode) return;

    // Step 1: Load cached translation if available
    const cacheKey = `connecta_translations_${languageCode}`;
    const cached = typeof window !== "undefined" ? localStorage.getItem(cacheKey) : null;

    if (cached) {
      try {
        setTranslations(JSON.parse(cached));
      } catch (e) {
        console.warn("âš ï¸ Failed to parse cached translations:", e);
      }
    }

    // Step 2: Fetch from Supabase
    const fetchTranslations = async () => {
      const { data, error } = await supabase
        .from("translations")
        .select("translations")
        .eq("language_code", languageCode)
        .single();

      if (!error && data?.translations) {
        setTranslations(data.translations);
        localStorage.setItem(cacheKey, JSON.stringify(data.translations));
      }
    };

    fetchTranslations();
  }, [languageCode]);

  return translations;
}

