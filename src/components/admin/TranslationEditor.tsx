"use client";

import { useEffect, useState, useRef } from "react";
import { supabase } from "@/lib/supabaseClient";
import Papa from "papaparse";

interface TranslationData {
  language_code: string;
  translations: Record<string, string>;
  base_translations?: Record<string, string>;
  keys?: string[];
}

export default function TranslationEditor() {
  const [languages, setLanguages] = useState<string[]>([]);
  const [language, setLanguage] = useState<string>("");
  const [translations, setTranslations] = useState<Record<string, string>>({});
  const [baseTranslations, setBaseTranslations] = useState<Record<string, string>>({});
  const [keys, setKeys] = useState<string[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState<boolean>(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Fetch available languages on mount
  useEffect(() => {
    async function fetchLanguages() {
      setLoading(true);
      setError(null);
      const { data, error } = await supabase
        .from("translations")
        .select("language_code");
      if (error) {
        setError("Error fetching languages: " + error.message);
        setLoading(false);
        return;
      }
      const langs = data?.map((d) => d.language_code) || [];
      setLanguages(langs);
      if (langs.length > 0) setLanguage(langs[0]);
      setLoading(false);
    }
    fetchLanguages();
  }, []);

  // Fetch translations for selected language
  useEffect(() => {
    if (!language) return;
    async function fetchTranslations() {
      setLoading(true);
      setError(null);

      // Fetch selected language translations + keys + base translations
      const { data, error } = await supabase
        .from<TranslationData>("translations")
        .select("translations, base_translations, keys")
        .eq("language_code", language)
        .single();

      if (error) {
        setError("Error fetching translations: " + error.message);
        setLoading(false);
        return;
      }

      setTranslations(data?.translations || {});
      setBaseTranslations(data?.base_translations || {});
      setKeys(data?.keys || Object.keys(data?.translations || {})); // fallback keys from translations
      setLoading(false);
    }
    fetchTranslations();
  }, [language]);

  function handleChange(key: string, value: string) {
    setTranslations((prev) => ({ ...prev, [key]: value }));
  }

  async function handleSave() {
    setSaving(true);
    setError(null);
    const { error } = await supabase
      .from("translations")
      .upsert([{ language_code: language, translations, base_translations: baseTranslations, keys }], {
        onConflict: "language_code",
      });
    if (error) setError("Error saving translations: " + error.message);
    else alert("Translations saved successfully!");
    setSaving(false);
  }

  function downloadJSON() {
    const blob = new Blob(
      [JSON.stringify({ keys, base_translations: baseTranslations, translations }, null, 2)],
      {
        type: "application/json",
      }
    );
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `${language}_translations.json`;
    a.click();
    URL.revokeObjectURL(url);
  }

  function downloadCSV() {
    const csvData = keys.map((key) => ({
      Key: key,
      English: baseTranslations[key] || "",
      Translation: translations[key] || "",
    }));
    const csv = Papa.unparse(csvData);
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `${language}_translations.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }

  async function handleUpload(e: React.ChangeEvent<HTMLInputElement>) {
    setError(null);
    const file = e.target.files?.[0];
    if (!file) return;

    const text = await file.text();

    let newTranslations: Record<string, string> = {};
    let newKeys: string[] = [];

    try {
      if (file.name.toLowerCase().endsWith(".json")) {
        const parsed = JSON.parse(text);
        if (parsed.translations) newTranslations = parsed.translations;
        if (parsed.keys) newKeys = parsed.keys;
        if (parsed.base_translations) setBaseTranslations(parsed.base_translations);
      } else if (file.name.toLowerCase().endsWith(".csv")) {
        const parsed = Papa.parse(text, { header: true });
        for (const row of parsed.data as any[]) {
          if (row.Key) {
            newTranslations[row.Key] = row.Translation || "";
            newKeys.push(row.Key);
          }
        }
      } else {
        setError("Unsupported file format. Please upload JSON or CSV.");
        return;
      }

      setKeys(newKeys.length > 0 ? newKeys : Object.keys(newTranslations));
      setTranslations(newTranslations);

      alert("File uploaded successfully. Don't forget to save changes!");
      if (fileInputRef.current) fileInputRef.current.value = "";
    } catch (err: any) {
      setError("Failed to parse uploaded file: " + err.message);
    }
  }

  return (
    <div className="p-4 max-w-5xl mx-auto">
      <h1 className="text-3xl font-bold mb-4">Translation Editor</h1>

      <label className="block mb-2 font-semibold">
        Select Language:
        <select
          value={language}
          onChange={(e) => setLanguage(e.target.value)}
          className="ml-2 p-2 border rounded"
          disabled={loading || saving}
        >
          {languages.map((lang) => (
            <option key={lang} value={lang}>
              {lang}
            </option>
          ))}
        </select>
      </label>

      {error && <div className="text-red-600 mb-4 font-semibold">{error}</div>}

      {loading ? (
        <p>Loading translations...</p>
      ) : (
        <>
          <table className="w-full border-collapse border border-gray-300 mb-4">
            <thead>
              <tr>
                <th className="border border-gray-300 px-3 py-1 text-left">Key</th>
                <th className="border border-gray-300 px-3 py-1 text-left">English</th>
                <th className="border border-gray-300 px-3 py-1 text-left">Translation</th>
              </tr>
            </thead>
            <tbody>
              {keys.map((key) => (
                <tr key={key}>
                  <td className="border border-gray-300 px-3 py-1 align-top">{key}</td>
                  <td className="border border-gray-300 px-3 py-1 align-top whitespace-pre-wrap">{baseTranslations[key]}</td>
                  <td className="border border-gray-300 px-3 py-1">
                    <textarea
                      className="w-full resize-none p-1"
                      rows={2}
                      value={translations[key] || ""}
                      onChange={(e) => handleChange(key, e.target.value)}
                      disabled={saving}
                    />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          <div className="space-x-3">
            <button
              onClick={handleSave}
              disabled={saving}
              className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
            >
              {saving ? "Saving..." : "Save Changes"}
            </button>

            <button
              onClick={downloadJSON}
              disabled={loading || saving}
              className="px-4 py-2 bg-gray-800 text-white rounded hover:bg-gray-900"
            >
              Download JSON
            </button>

            <button
              onClick={downloadCSV}
              disabled={loading || saving}
              className="px-4 py-2 bg-gray-800 text-white rounded hover:bg-gray-900"
            >
              Download CSV
            </button>

            <label
              htmlFor="upload-file"
              className={`px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 cursor-pointer ${
                saving ? "opacity-50 cursor-not-allowed" : ""
              }`}
            >
              Upload JSON/CSV
            </label>
            <input
              type="file"
              id="upload-file"
              accept=".json,.csv"
              onChange={handleUpload}
              className="hidden"
              ref={fileInputRef}
              disabled={saving}
            />
          </div>
        </>
      )}
    </div>
  );
}

