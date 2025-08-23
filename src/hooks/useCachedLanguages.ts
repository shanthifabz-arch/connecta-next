"use client";

import { useEffect, useState } from "react";
import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;
const supabase = createClient(supabaseUrl, supabaseAnonKey);

type LanguageEntry = {
  language_code: string;
  display_name: string;
  emoji_flag?: string;
};

export function useCachedLanguages(): LanguageEntry[] {
  const [languageOptions, setLanguageOptions] = useState<LanguageEntry[]>([]);

  useEffect(() => {
    // Step 1: Load from localStorage instantly
    const cached = typeof window !== "undefined" ? localStorage.getItem("connecta_languages") : null;
    if (cached) {
      try {
        setLanguageOptions(JSON.parse(cached));
      } catch (e) {
        console.warn("âš ï¸ Failed to parse cached languages:", e);
      }
    }

    // Step 2: Fetch fresh data from Supabase
    const fetchLanguages = async () => {
      const { data, error } = await supabase
        .from("translations")
        .select("language_code, display_name, emoji_flag");

      if (!error && data) {
        setLanguageOptions(data);
        localStorage.setItem("connecta_languages", JSON.stringify(data));
      }
    };

    fetchLanguages();
  }, []);

  return languageOptions;
}

