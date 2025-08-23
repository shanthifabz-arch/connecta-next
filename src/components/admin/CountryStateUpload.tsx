"use client";

import { useState, useEffect } from "react";
import { supabase } from "@/lib/supabaseClient";

interface CountryStateData {
  [country: string]: string[];
}

interface CountryStateRow {
  id?: number; // Assuming PK
  country: string;
  states: string[];
  active: boolean;
}

export default function CountryStateUpload() {
  const [jsonPreview, setJsonPreview] = useState<CountryStateData>({});
  const [fileName, setFileName] = useState("");
  const [status, setStatus] = useState("");
  const [isUploading, setIsUploading] = useState(false);

  const [countries, setCountries] = useState<CountryStateRow[]>([]);
  const [loadingCountries, setLoadingCountries] = useState(true);

  // Fetch countries from Supabase on load
  useEffect(() => {
    async function fetchCountries() {
      setLoadingCountries(true);
      const { data, error } = await supabase
        .from("country_states")
        .select("*")
        .order("country", { ascending: true });
      if (error) {
        console.error("Error fetching countries:", error);
        setStatus("âŒ Error fetching countries.");
      } else {
        setCountries(data as CountryStateRow[]);
        setStatus("");
      }
      setLoadingCountries(false);
    }
    fetchCountries();
  }, []);

  // Handle toggle active state change
  const toggleActive = (index: number) => {
    setCountries((prev) => {
      const newCountries = [...prev];
      newCountries[index].active = !newCountries[index].active;
      return newCountries;
    });
  };

  // **Add this: handleFileUpload function**
  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setFileName(file.name);
    setStatus("");
    setJsonPreview({});

    try {
      const text = await file.text();
      const json = JSON.parse(text) as CountryStateData;

      // Validate JSON structure: country: array of strings
      const isValid = Object.entries(json).every(
        ([_, states]) =>
          Array.isArray(states) && states.every((s) => typeof s === "string")
      );

      if (!isValid) {
        setStatus("âŒ Invalid JSON structure: states must be arrays of strings.");
        return;
      }

      setJsonPreview(json);
      setStatus("âœ… JSON file loaded. Ready to upload.");
    } catch (err) {
      console.error("JSON Parse Error:", err);
      setStatus("âŒ Invalid JSON format.");
    }
  };

  // **Add this: handleUploadToSupabase function**
  const handleUploadToSupabase = async () => {
    if (!Object.keys(jsonPreview).length) return;

    setIsUploading(true);
    setStatus("Uploading... Please wait.");

    // Prepare rows: [{ country: 'India', states: [ ... ] }, ...]
    const rows = Object.entries(jsonPreview).map(([country, states]) => ({
      country,
      states, // pass as jsonb array
      active: true, // default active true for new entries (adjust if needed)
    }));

    try {
      const { error } = await supabase
        .from("country_states")
        .upsert(rows, { onConflict: ["country"] }); // unique constraint on country required

      if (error) {
        console.error("Supabase Insert Error:", error);
        setStatus("âŒ Upload failed. Check console for details.");
      } else {
        setStatus(`âœ… Successfully uploaded ${rows.length} countries.`);
        setJsonPreview({});
        setFileName("");

        // Refresh the countries list to show updated data
        const { data } = await supabase
          .from("country_states")
          .select("*")
          .order("country", { ascending: true });
        if (data) setCountries(data as CountryStateRow[]);
      }
    } catch (error) {
      console.error("Unexpected error:", error);
      setStatus("âŒ Unexpected error occurred during upload.");
    }

    setIsUploading(false);
  };

  return (
    <div className="bg-white border rounded-xl p-6 shadow-md max-w-3xl mx-auto">
      <h2 className="text-xl font-bold mb-4 text-blue-600">
        Upload Countryâ€"State JSON
      </h2>

      <input
        type="file"
        accept=".json"
        onChange={handleFileUpload}
        className="mb-4"
      />

      {fileName && (
        <p className="text-sm text-gray-500 mb-2">Loaded File: {fileName}</p>
      )}

      {/* JSON Preview and upload button */}
      {Object.keys(jsonPreview).length > 0 && (
        <>
          <div className="bg-gray-50 border p-4 rounded h-64 overflow-y-scroll text-sm mb-4">
            <p className="font-semibold mb-2">Preview:</p>
            {Object.entries(jsonPreview).map(([country, states]) => (
              <div key={country}>
                <strong>{country}</strong>
                <ul className="ml-4 list-disc">
                  {states.map((state) => (
                    <li key={`${country}-${state}`}>{state}</li>
                  ))}
                </ul>
              </div>
            ))}
          </div>

          <button
            onClick={handleUploadToSupabase}
            disabled={isUploading}
            className={`px-4 py-2 rounded ${
              isUploading
                ? "bg-gray-400 cursor-not-allowed"
                : "bg-green-600 hover:bg-green-700"
            } text-white`}
          >
            {isUploading ? "Uploading..." : "Upload to Supabase"}
          </button>
        </>
      )}

      {/* Show fetched countries with toggles */}
      <div className="mt-8">
        <h3 className="text-lg font-semibold mb-3">Countries List</h3>
        {loadingCountries ? (
          <p>Loading countries...</p>
        ) : countries.length === 0 ? (
          <p>No countries found.</p>
        ) : (
          <ul>
            {countries.map(({ country, active }, idx) => (
              <li key={country} className="flex items-center mb-2">
                <label className="flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={active}
                    onChange={() => toggleActive(idx)}
                    className="mr-2"
                  />
                  <span>{country}</span>
                </label>
              </li>
            ))}
          </ul>
        )}
      </div>

      {status && <p className="mt-4 text-sm text-blue-700">{status}</p>}
    </div>
  );
}

