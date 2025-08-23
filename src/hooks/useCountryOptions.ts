import { useState, useEffect } from "react";
import { supabase } from "@/lib/supabaseClient";

export function useCountryStateOptions() {
  const [countries, setCountries] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchCountries() {
      setLoading(true);

      const { data, error } = await supabase
        .from("country_states")
        .select("country")
        .order("country", { ascending: true });

      if (error) {
        console.error("Error fetching countries:", error.message);
        setCountries([]);
      } else if (data) {
        // Extract country names from data
        const countryNames = data.map((row) => row.country);
        setCountries(countryNames);
      }

      setLoading(false);
    }

    fetchCountries();
  }, []);

  return { countries, loading };
}

