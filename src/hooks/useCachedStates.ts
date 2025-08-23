"use client";

import { useEffect, useState } from "react";
import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;
const supabase = createClient(supabaseUrl, supabaseAnonKey);

type State = {
  name: string;
  country: string;
};

export function useCachedStates(): State[] {
  const [states, setStates] = useState<State[]>([]);

  useEffect(() => {
    const cached = typeof window !== "undefined" ? localStorage.getItem("connecta_states") : null;

    if (cached) {
      try {
        setStates(JSON.parse(cached));
      } catch (e) {
        console.warn("âš ï¸ Failed to parse cached states");
      }
    }

    const fetchStates = async () => {
      const { data, error } = await supabase
        .from("states")
        .select("name, country")
        .order("name");

      if (!error && data) {
        setStates(data);
        localStorage.setItem("connecta_states", JSON.stringify(data));
      }
    };

    fetchStates();
  }, []);

  return states;
}

