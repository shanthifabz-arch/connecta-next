"use client";

import { useEffect, useState } from "react";
import * as XLSX from "xlsx";
import { supabase } from "@/lib/supabaseClient";  // Make sure this exists and is configured

interface ArchiveEntry {
  fileName: string;
  timestamp: number;
  language: string;
}

export default function TranslationEditor() {
  const [language, setLanguage] = useState("ta");
  const [translations, setTranslations] = useState<Record<string, string>>({});
  const [englishBase, setEnglishBase] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [saveStatus, setSaveStatus] = useState<string | null>(null);
  const [archive, setArchive] = useState<ArchiveEntry[]>([]);
  const [overwriteMode, setOverwriteMode] = useState(true);

  const languageColumnMap: Record<string, string> = {
    af: "Afrikaans",
    sq: "Albanian",
    am: "Amharic",
    ar: "Arabic",
    // ... full map as before ...
    zu: "Zulu",
  };

  // Fetch translations from Supabase by language code
  async function fetchTranslationsFromSupabase(lang: string) {
    const { data, error } = await supabase
      .from("translations")
      .select("translations")
      .eq("language_code", lang)
      .single();

    if (error || !data) throw new Error(error?.message || "No data");
    return data.translations as Record<string, string>;
  }

  // Save translations to Supabase (upsert)
  async function saveTranslationsToSupabase(lang: string, translationsObj: Record<string, string>) {
    const { error } = await supabase
      .from("translations")
      .upsert({ language_code: lang, translations: translationsObj }, { onConflict: "language_code" });
    if (error) throw new Error(error.message);
  }

  useEffect(() => {
    const loadTranslations = async () => {
      setLoading(true);
      try {
        // Always load English base from local JSON for keys template
        const enRes = await fetch("/locales/en/translation_master.json");
        const enJson = await enRes.json();
        setEnglishBase(enJson);

        // Try loading translations from Supabase first
        let loadedTranslations: Record<string, string> = {};
        try {
          loadedTranslations = await fetchTranslationsFromSupabase(language);
          setSaveStatus(`âœ… Loaded translations for '${language}' from Supabase.`);
        } catch (supabaseErr) {
          // If Supabase fails, fallback to local JSON files
          setSaveStatus(`âš ï¸ Supabase fetch failed. Falling back to local JSON.`);
          try {
            let langRes = await fetch(`/locales/${language}/translation.json`);
            if (!langRes.ok) {
              const fallbackLang = language.split("-")[0];
              langRes = await fetch(`/locales/${fallbackLang}/translation.json`);
              if (!langRes.ok) throw new Error("Fallback JSON not found");
            }
            loadedTranslations = await langRes.json();
          } catch (jsonErr) {
            console.error("Error loading fallback JSON translations", jsonErr);
          }
        }
        setTranslations(loadedTranslations);
        loadArchive();
      } catch (err) {
        console.error("Error loading translations", err);
        setSaveStatus(`âŒ Error loading translations: ${err.message}`);
      } finally {
        setLoading(false);
      }
    };
    loadTranslations();
  }, [language]);

  const loadArchive = () => {
    const raw = localStorage.getItem(`archive_${language}`);
    if (!raw) return;
    try {
      const files: ArchiveEntry[] = JSON.parse(raw);
      setArchive(files);
    } catch (err) {
      console.error("Invalid archive data", err);
    }
  };

  const handleChange = (key: string, value: string) => {
    setTranslations((prev) => ({ ...prev, [key]: value }));
  };

  // Save JSON download + update archive locally
  const handleSave = async () => {
    try {
      if (Object.keys(translations).length === 0) {
        setSaveStatus("âŒ No translations to save.");
        return;
      }
      const timestamp = Date.now();
      const fileName = `translation_v${timestamp}.json`;
      const json = JSON.stringify(translations, null, 2);
      const blob = new Blob([json], { type: "application/json" });
      const link = document.createElement("a");
      link.href = URL.createObjectURL(blob);
      link.download = fileName;
      link.click();

      const entry: ArchiveEntry = { fileName, timestamp, language };
      const updatedArchive = [entry, ...archive];
      localStorage.setItem(`archive_${language}`, JSON.stringify(updatedArchive));
      setArchive(updatedArchive);
      setSaveStatus("âœ… Downloaded JSON as " + fileName);
    } catch (err) {
      console.error("Error saving JSON", err);
      setSaveStatus("âŒ Save failed.");
    }
  };

  // Export current translations as Excel
  const handleExportExcel = () => {
    if (Object.keys(englishBase).length === 0) {
      setSaveStatus("âŒ English base translations missing.");
      return;
    }
    const data = Object.entries(englishBase).map(([key, enText]) => ({
      Key: key,
      English: enText,
      [languageColumnMap[language] || language]: translations[key] || "",
    }));

    const worksheet = XLSX.utils.json_to_sheet(data);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, "Translations");

    XLSX.writeFile(workbook, `translations_${language}.xlsx`);
    setSaveStatus(`âœ… Excel exported: translations_${language}.xlsx`);
  };

  // Revert translation to a previously saved JSON version from local archive
  const handleRevert = async (fileName: string) => {
    try {
      const filePath = `/locales/${language}/${fileName}`;
      const res = await fetch(filePath);
      const json = await res.json();
      setTranslations(json);
      setSaveStatus("Reverted to: " + fileName);
    } catch (err) {
      console.error("Error reverting file", err);
      setSaveStatus("Revert failed.");
    }
  };

  // Upload Excel, parse, update state, AND save to Supabase (upsert)
  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = async (evt) => {
      const data = new Uint8Array(evt.target?.result as ArrayBuffer);
      const workbook = XLSX.read(data, { type: "array" });
      const sheet = workbook.Sheets[workbook.SheetNames[0]];
      const rows = XLSX.utils.sheet_to_json(sheet);
      const updates: Record<string, string> = {};

      const langColumn = languageColumnMap[language] || language;
      rows.forEach((row: any) => {
        const key = row.Key;
        const value = row[langColumn];
        if (key && value) {
          updates[key] = value;
        }
      });

      try {
        await saveTranslationsToSupabase(language, updates);
        setSaveStatus(`âœ… Uploaded translations to Supabase for '${language}'.`);
      } catch (err) {
        console.error("Supabase upload failed", err);
        setSaveStatus(`âŒ Supabase upload failed: ${err.message}`);
      }

      setTranslations((prev) => (overwriteMode ? updates : { ...prev, ...updates }));
    };
    reader.readAsArrayBuffer(file);
  };

  const formatDate = (timestamp: number) => {
    const d = new Date(timestamp);
    return d.toLocaleString();
  };

  return (
    <div className="p-4">
      <h2 className="text-2xl font-bold mb-4">Live Table Editor</h2>

      <label className="block mb-2">
        Select Language:
        <select
          className="ml-2 p-2 border rounded"
          value={language}
          onChange={(e) => setLanguage(e.target.value)}
        >
          {Object.entries(languageColumnMap).map(([code, label]) => (
            <option key={code} value={code}>
              {label} ({code})
            </option>
          ))}
        </select>
      </label>

      <label className="block mb-4">
        Upload Excel File:
        <input type="file" accept=".xlsx" onChange={handleFileUpload} />
      </label>

      <label className="block mb-4">
        <input
          type="checkbox"
          checked={overwriteMode}
          onChange={() => setOverwriteMode(!overwriteMode)}
        />
        <span className="ml-2">Overwrite existing translations</span>
      </label>

      <div className="flex gap-2 mb-4">
        <button
          onClick={handleSave}
          className="bg-blue-600 text-white px-4 py-2 rounded"
        >
          Save Translation as JSON
        </button>

        <button
          onClick={handleExportExcel}
          className="bg-green-600 text-white px-4 py-2 rounded"
        >
          Export as Excel
        </button>
      </div>

      {loading ? (
        <p>Loading translations...</p>
      ) : (
        <div className="overflow-x-auto">
          <table className="min-w-full border">
            <thead className="bg-gray-100">
              <tr>
                <th className="border px-4 py-2 text-left">Key</th>
                <th className="border px-4 py-2 text-left">English</th>
                <th className="border px-4 py-2 text-left">{language.toUpperCase()}</th>
              </tr>
            </thead>
            <tbody>
              {Object.entries(englishBase).map(([key, enText]) => (
                <tr key={key}>
                  <td className="border px-4 py-2 text-sm">{key}</td>
                  <td className="border px-4 py-2 text-sm">{enText}</td>
                  <td className="border px-4 py-2">
                    <input
                      className="w-full border rounded px-2 py-1 text-sm"
                      type="text"
                      value={translations[key] || ""}
                      onChange={(e) => handleChange(key, e.target.value)}
                    />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {saveStatus && <p className="mt-2 text-green-600">{saveStatus}</p>}

      {archive.length > 0 && (
        <div className="mt-6">
          <h3 className="text-lg font-semibold mb-2">Previous Versions</h3>
          <table className="min-w-full border">
            <thead className="bg-gray-100">
              <tr>
                <th className="border px-4 py-2">S.No</th>
                <th className="border px-4 py-2">File Name</th>
                <th className="border px-4 py-2">Language Code</th>
                <th className="border px-4 py-2">Saved On</th>
              </tr>
            </thead>
            <tbody>
              {archive.map((entry, index) => (
                <tr key={index}>
                  <td className="border px-4 py-2 text-center">{index + 1}</td>
                  <td className="border px-4 py-2">
                    <button
                      onClick={() => handleRevert(entry.fileName)}
                      className="text-blue-700 underline"
                    >
                      {entry.fileName}
                    </button>
                  </td>
                  <td className="border px-4 py-2 text-center">{entry.language}</td>
                  <td className="border px-4 py-2 text-sm">{formatDate(entry.timestamp)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

