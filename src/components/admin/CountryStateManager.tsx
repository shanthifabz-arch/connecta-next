"use client";

import React, { useEffect, useState } from "react";
import { supabase } from "@/lib/supabaseClient";
import EditableCountryList from "./CountryStateEditableList";

interface State {
  name: string;
  active: boolean;
}

interface CountryStateRow {
  id?: number;
  country: string;
  states: State[];
  active: boolean;
}

const indianStates: State[] = [
  { name: "Andhra Pradesh", active: true },
  { name: "Arunachal Pradesh", active: true },
  { name: "Assam", active: true },
  { name: "Bihar", active: true },
  { name: "Chhattisgarh", active: true },
  { name: "Goa", active: true },
  { name: "Gujarat", active: true },
  { name: "Haryana", active: true },
  { name: "Himachal Pradesh", active: true },
  { name: "Jharkhand", active: true },
  { name: "Karnataka", active: true },
  { name: "Kerala", active: true },
  { name: "Madhya Pradesh", active: true },
  { name: "Maharashtra", active: true },
  { name: "Manipur", active: true },
  { name: "Meghalaya", active: true },
  { name: "Mizoram", active: true },
  { name: "Nagaland", active: true },
  { name: "Odisha", active: true },
  { name: "Punjab", active: true },
  { name: "Rajasthan", active: true },
  { name: "Sikkim", active: true },
  { name: "Tamil Nadu", active: true },
  { name: "Telangana", active: true },
  { name: "Tripura", active: true },
  { name: "Uttar Pradesh", active: true },
  { name: "Uttarakhand", active: true },
  { name: "West Bengal", active: true }
];

export default function CountryStateManager() {
  const [countries, setCountries] = useState<CountryStateRow[]>([]);
  const [filteredCountries, setFilteredCountries] = useState<CountryStateRow[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState("");

  // Fetch countries from Supabase
  const fetchCountries = async () => {
    setLoading(true);
    const { data, error } = await supabase
      .from("country_states")
      .select("*")
      .order("country", { ascending: true });
    if (error) {
      setStatus(`Error fetching countries: ${error.message}`);
    } else if (data) {
      setCountries(data as CountryStateRow[]);
      setFilteredCountries(data as CountryStateRow[]);
      setStatus("");
    }
    setLoading(false);
  };

  useEffect(() => {
    fetchCountries();
  }, []);

  // Search filter handler
  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const term = e.target.value;
    setSearchTerm(term);
    if (!term) {
      setFilteredCountries(countries);
      return;
    }
    const filtered = countries.filter((c) =>
      c.country.toLowerCase().includes(term.toLowerCase())
    );
    setFilteredCountries(filtered);
  };

  // Toggle active status
  const handleToggleActive = (id: number | undefined, active: boolean) => {
    setCountries((prev) =>
      prev.map((c) => (c.id === id ? { ...c, active } : c))
    );
    setFilteredCountries((prev) =>
      prev.map((c) => (c.id === id ? { ...c, active } : c))
    );
  };

 // Save updated country back to Supabase
const handleSave = async (updatedCountry: CountryStateRow) => {
  setStatus("Saving changes...");

  // Preserve your India override exactly
  if (updatedCountry.country.toLowerCase() === "india") {
    updatedCountry.states = indianStates;
  }

  // In supabase-js v2, onConflict must be a STRING, not string[]
  // We also request the row back to keep local state perfectly in sync
  const { data: saved, error } = await supabase
    .from("country_states")
   .upsert([updatedCountry]).select().single();

  if (error) {
    setStatus(`Error saving: ${error.message}`);
  } else {
    const next = saved ?? updatedCountry;
    setStatus("Changes saved successfully.");

    setCountries((prev) =>
      prev.map((c) => (c.id === next.id ? next : c))
    );
    setFilteredCountries((prev) =>
      prev.map((c) => (c.id === next.id ? next : c))
    );
  }
};


  return (
    <div className="max-w-4xl mx-auto p-6 bg-white rounded shadow">
      <h2 className="text-2xl font-bold mb-4 text-blue-600">Country & State Manager</h2>

      <input
        type="text"
        placeholder="Search country..."
        value={searchTerm}
        onChange={handleSearchChange}
        className="w-full mb-4 px-3 py-2 border rounded"
      />

      {loading && <p>Loading countries...</p>}
      {status && <p className="mb-4 text-sm text-red-600">{status}</p>}

      {!loading && filteredCountries.length === 0 && <p>No countries found.</p>}

      {!loading && filteredCountries.length > 0 && (
        <EditableCountryList
          countries={filteredCountries}
          onToggleActive={handleToggleActive}
          onSave={handleSave}
        />
      )}
    </div>
  );
}

