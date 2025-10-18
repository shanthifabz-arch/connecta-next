"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabaseClient";

type Translations = Record<string, string>;

export default function TranslationUpload() {
  const [languageCode, setLanguageCode] = useState("");
  const [fileName, setFileName] = useState("");
  const [status, setStatus] = useState("");
  const [translations, setTranslations] = useState<Translations>({});
  const [keys, setKeys] = useState<string[]>([]);
  const [englishTexts, setEnglishTexts] = useState<Translations>({});

  // Load English base texts once
  useEffect(() => {
    // Replace/extend this with your actual English keys or fetch them if needed
    const baseEnglish: Translations = {
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

    (async () => {
      try {
        setStatus("Fetching translations…");
        const { data, error } = await supabase
          .from("translations")
          .select("translations")
          .eq("language_code", languageCode.trim())
          .maybeSingle();

        if (error) {
          setTranslations({});
          setStatus(`Error fetching translations: ${error.message}`);
          return;
        }

        const payload = (data?.translations ?? {}) as Translations;
        setTranslations(payload);
        setStatus("Translations loaded.");
      } catch (e: any) {
        setTranslations({});
        setStatus(`Error fetching translations: ${e?.message ?? String(e)}`);
      }
    })();
  }, [languageCode]);

  // Handle JSON file upload for bulk translations
  const handleJSONUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setFileName(file.name);
    setStatus("Reading file…");

    const reader = new FileReader();
    reader.onload = async (event) => {
      try {
        const content = String(event.target?.result ?? "");
        const json = JSON.parse(content);

        if (!languageCode.trim()) {
          setStatus("Please select a language code before uploading.");
          return;
        }

        // Validate the JSON is a flat key→string object
        if (
          typeof json !== "object" ||
          Array.isArray(json) ||
          json === null
        ) {
          setStatus("Invalid JSON: expected an object of key→string pairs.");
          return;
        }

        const { error } = await supabase
          .from("translations")
          .upsert(
            {
              language_code: languageCode.trim(),
              translations: json,
            },
            { onConflict: "language_code" }
          );

        if (error) {
          console.error("Supabase upsert error:", error.message);
          setStatus(`Upload failed: ${error.message}`);
          return;
        }

        setTranslations(json as Translations);
        setStatus("Translation JSON uploaded successfully.");
      } catch (err: any) {
        console.error("JSON parsing error:", err);
        setStatus(`Invalid JSON file: ${err?.message ?? String(err)}`);
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
    if (!languageCode.trim()) {
      setStatus("Please enter a language code before saving.");
      return;
    }
    try {
      setStatus("Saving translations…");
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
        setStatus(`Error saving translations: ${error.message}`);
      } else {
        setStatus("Translations saved successfully.");
      }
    } catch (e: any) {
      setStatus(`Error saving translations: ${e?.message ?? String(e)}`);
    }
  };

  return (
    <div className="p-4 border rounded shadow-sm bg-white max-w-3xl mx-auto mt-4">
      <h2 className="text-lg font-bold text-blue-700 mb-4">
        Upload Translations (JSON)
      </h2>

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

      {fileName && <p className="text-sm text-gray-600">{fileName}</p>}
      {status && <p className="mt-2 text-sm font-medium">{status}</p>}

      <h3 className="mt-6 mb-2 font-semibold">Translation Editor</h3>
      <div className="overflow-x-auto">
        <table className="w-full border border-gray-300 text-left text-sm">
          <thead>
            <tr className="bg-gray-100">
              <th className="border px-3 py-1">Key</th>
              <th className="border px-3 py-1">English</th>
              <th className="border px-3 py-1">Translation</th>
            </tr>
          </thead>
          <tbody>
            {keys.map((k) => (
              <tr key={k}>
                <td className="border px-3 py-1 align-top">{k}</td>
                <td className="border px-3 py-1 align-top">{englishTexts[k]}</td>
                <td className="border px-3 py-1">
                  <input
                    type="text"
                    className="w-full border rounded p-1"
                    value={translations[k] ?? ""}
                    onChange={(e) => handleTranslationChange(k, e.target.value)}
                  />
                </td>
              </tr>
            ))}
            {keys.length === 0 && (
              <tr>
                <td className="border px-3 py-2 text-gray-500" colSpan={3}>
                  No base keys defined yet.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      <button
        onClick={saveTranslations}
        className="mt-4 bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
      >
        Save Translations
      </button>
    </div>
  );
}
