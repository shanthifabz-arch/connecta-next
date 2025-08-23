"use client";

import { useState, useEffect } from "react";
import { supabase } from "@/lib/supabaseClient";

export default function TranslationUpload() {
  const [languageCode, setLanguageCode] = useState("");
  const [fileName, setFileName] = useState("");
  const [status, setStatus] = useState("");
  const [translations, setTranslations] = useState<Record<string, string>>({});
  const [keys, setKeys] = useState<string[]>([]);
  const [englishTexts, setEnglishTexts] = useState<Record<string, string>>({});

  // Load English base texts once
  useEffect(() => {
    // Replace with your actual English keys and texts or fetch from backend if needed
    const baseEnglish = {
      welcome_heading: "Welcome to CONNECTA",
      welcome_subtitle: "Please upload your QR code or enter the referral code",
      upload_qr: "Upload QR Code",
      // Add all your translation keys and English texts here
    };
    setKeys(Object.keys(baseEnglish));
    setEnglishTexts(baseEnglish);
  }, []);

  // Fetch translations for selected language
  useEffect(() => {
    if (!languageCode) return;

    async function fetchTranslations() {
      setStatus("Fetching translations...");
      const { data, error } = await supabase
        .from("translations")
        .select("translations")
        .eq("language_code", languageCode.trim())
        .single();

      if (error) {
        setStatus(`âŒ Error fetching translations: ${error.message}`);
        setTranslations({});
      } else {
        setTranslations(data?.translations || {});
        setStatus("âœ… Translations loaded.");
      }
    }

    fetchTranslations();
  }, [languageCode]);

  // Handle JSON file upload for bulk translations
  const handleJSONUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setFileName(file.name);
    setStatus("Reading file...");

    const reader = new FileReader();
    reader.onload = async (event) => {
      try {
        const content = event.target?.result as string;
        const json = JSON.parse(content);

        if (!languageCode) {
          setStatus("âŒ Please select a language code.");
          return;
        }

        const { data, error } = await supabase
          .from("translations")
          .upsert(
            {
              language_code: languageCode.trim(),
              translations: json,
            },
            { onConflict: "language_code" }
          );

        if (error) {
          console.error("âŒ Supabase error:", error.message);
          setStatus("âŒ Upload failed.");
        } else {
          setTranslations(json);
          setStatus("âœ… Translation JSON uploaded successfully.");
        }
      } catch (err) {
        console.error("âŒ JSON parsing error:", err);
        setStatus("âŒ Invalid JSON file.");
      }
    };

    reader.readAsText(file);
  };

  // Handle inline translation edits
  const handleTranslationChange = (key: string, value: string) => {
    setTranslations((prev) => ({ ...prev, [key]: value }));
  };

  // Save edited translations back to Supabase
  const saveTranslations = async () => {
    if (!languageCode) {
      setStatus("âŒ Please enter a language code before saving.");
      return;
    }
    setStatus("Saving translations...");
    const { error } = await supabase
      .from("translations")
      .upsert(
        {
          language_code: languageCode.trim(),
          translations: translations,
        },
        { onConflict: "language_code" }
      );

    if (error) {
      setStatus(`âŒ Error saving translations: ${error.message}`);
    } else {
      setStatus("âœ… Translations saved successfully.");
    }
  };

  return (
    <div className="p-4 border rounded shadow-sm bg-white max-w-xl mx-auto mt-4">
      <h2 className="text-lg font-bold text-blue-700 mb-4">ðŸ"„ Upload Translations (JSON)</h2>

      <input
        type="text"
        placeholder="Language Code (e.g., ta)"
        value={languageCode}
        onChange={(e) => setLanguageCode(e.target.value)}
        className="border p-2 rounded w-full mb-4"
      />

      <label className="block mb-4 cursor-pointer">
        <span className="text-blue-600 underline">Select JSON File</span>
        <input type="file" accept=".json" onChange={handleJSONUpload} className="hidden" />
      </label>

      {fileName && <p className="text-sm text-gray-600">ðŸ"‚ {fileName}</p>}
      {status && <p className="mt-2 text-sm font-medium">{status}</p>}

      <h3 className="mt-6 mb-2 font-semibold">Translation Editor</h3>
      <table className="w-full border border-gray-300 text-left text-sm">
        <thead>
          <tr className="bg-gray-100">
            <th className="border px-3 py-1">Key</th>
            <th className="border px-3 py-1">English</th>
            <th className="border px-3 py-1">Translation</th>
          </tr>
        </thead>
        <tbody>
          {keys.map((key) => (
            <tr key={key}>
              <td className="border px-3 py-1">{key}</td>
              <td className="border px-3 py-1">{englishTexts[key]}</td>
              <td className="border px-3 py-1">
                <input
                  type="text"
                  className="w-full border rounded p-1"
                  value={translations[key] || ""}
                  onChange={(e) => handleTranslationChange(key, e.target.value)}
                />
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      <button
        onClick={saveTranslations}
        className="mt-4 bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
      >
        Save Translations
      </button>
    </div>
  );
}

