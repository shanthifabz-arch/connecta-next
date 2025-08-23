"use client";

import { useEffect, useState } from "react";
import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;
const supabase = createClient(supabaseUrl, supabaseAnonKey);

type Country = {
  name: string;
  code?: string;
};

export function useCachedCountries(): Country[] {
  const [countries, setCountries] = useState<Country[]>([]);

  useEffect(() => {
    const cached = typeof window !== "undefined" ? localStorage.getItem("connecta_countries") : null;

    if (cached) {
      try {
        setCountries(JSON.parse(cached));
      } catch (e) {
        console.warn("âš ï¸ Failed to parse cached countries");
      }
    }

    const fetchCountries = async () => {
      const { data, error } = await supabase
        .from("countries")
        .select("name, code")
        .order("name");

      if (!error && data) {
        setCountries(data);
        localStorage.setItem("connecta_countries", JSON.stringify(data));
      }
    };

    fetchCountries();
  }, []);

  return countries;
}

