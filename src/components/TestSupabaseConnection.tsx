"use client";

import { useEffect } from "react";
import { supabase } from "@/lib/supabaseClient";

export default function TestSupabaseConnection() {
  useEffect(() => {
    supabase
      .from("translations")
      .select("*")
      .limit(1)
      .then(({ data, error }) => {
        if (error) {
          console.error("Supabase test query error:", error);
        } else {
          console.log("Supabase test query success:", data);
        }
      });
  }, []);

  return <div>Check console for Supabase test results</div>;
}

