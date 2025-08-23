"use client";

import React, { useState, useEffect } from "react";
import { supabase } from "@/lib/supabaseClient";

export default function TranslationViewer() {
  const [languageCode, setLanguageCode] = useState("");
  const [availableCodes, setAvailableCodes] = useState<string[]>([]);
  const [translations, setTranslations] = useState<Record<string, string>>({});
  const [status, setStatus] = useState("");

  useEffect(() => {
    fetchAvailableCodes();
  }, []);

  const fetchAvailableCodes = async () => {
    const { data, error } = await supabase
      .from("translations")
      .select("language_code");
    if (error) {
      setStatus("âŒ Error fetching language codes: " + error.message);
      return;
    }
    if (data) {
      const codes = Array.from(new Set(data.map((item: any) => item.language_code)));
      setAvailableCodes(codes);
    }
  };

  const handleFetch = async () => {
    if (!languageCode) {
      setStatus("âŒ Please select a language code.");
      return;
    }

    const { data, error } = await supabase
      .from("translations")
      .select("translations")
      .eq("language_code", languageCode)
      .single();

    if (error || !data) {
      setStatus("âŒ No translation found for this code.");
      setTranslations({});
    } else {
      setTranslations(data.translations || {});
      setStatus("âœ… Translations loaded.");
    }
  };

  return (
    <div className="p-4 max-w-3xl mx-auto">
      <h2 className="text-lg font-bold text-blue-700 mb-4">
        ðŸ" View Translations from Supabase
      </h2>

      <div className="flex gap-2 mb-4">
        <select
          value={languageCode}
          onChange={(e) => setLanguageCode(e.target.value)}
          className="p-2 border rounded"
        >
          <option value="">Select Language Code</option>
          {availableCodes.map((code) => (
            <option key={code} value={code}>
              {code}
            </option>
          ))}
        </select>

        <button
          onClick={handleFetch}
          className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
        >
          Load
        </button>
      </div>

      {status && <p className="mb-4 font-medium text-sm">{status}</p>}

      {Object.keys(translations).length > 0 && (
        <div className="overflow-auto max-h-[500px] border p-4 rounded bg-gray-50 text-sm">
          <table className="min-w-full">
            <thead>
              <tr className="text-left">
                <th className="border p-2">Key</th>
                <th className="border p-2">Value</th>
              </tr>
            </thead>
            <tbody>
              {Object.entries(translations).map(([key, value]) => (
                <tr key={key}>
                  <td className="border p-2 font-mono text-blue-900">{key}</td>
                  <td className="border p-2 text-gray-800">{value}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

