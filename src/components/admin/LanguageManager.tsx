"use client";

import React, { useState, useEffect } from "react";
import { supabase } from "@/lib/supabaseClient";
import { UploadCloud, Trash2 } from "lucide-react";

interface Language {
  id: string;
  code: string;
  label: string;
  script: string;
  enabled: boolean;
  created_at: string;
}

export default function LanguageManager() {
  const [languages, setLanguages] = useState<Language[]>([]);
  const [loading, setLoading] = useState(true);
  const [newCode, setNewCode] = useState("");
  const [newLabel, setNewLabel] = useState("");
  const [newScript, setNewScript] = useState("");
  const [error, setError] = useState("");

  useEffect(() => {
    fetchLanguages();
  }, []);

  const fetchLanguages = async () => {
    setLoading(true);
    const { data, error } = await supabase
      .from("languages")
      .select("*")
      .order("label", { ascending: true });

    if (error) {
      console.error("Error fetching languages:", error.message);
    } else {
      setLanguages(data as Language[]);
    }

    setLoading(false);
  };

  const handleAddLanguage = async () => {
    setError("");
    if (!newCode || !newLabel || !newScript) {
      setError("All fields are required.");
      return;
    }

    const duplicate = languages.find(
      (lang) => lang.code.toLowerCase() === newCode.toLowerCase()
    );
    if (duplicate) {
      setError("Language code already exists.");
      return;
    }

    const { error } = await supabase.from("languages").insert([
      {
        code: newCode.trim(),
        label: newLabel.trim(),
        script: newScript.trim(),
        enabled: true,
      },
    ]);

    if (error) {
      alert(" Failed to add language.");
      console.error(error);
    } else {
      setNewCode("");
      setNewLabel("");
      setNewScript("");
      fetchLanguages();
    }
  };

  const handleToggleEnabled = async (id: string, newStatus: boolean) => {
    const { error } = await supabase
      .from("languages")
      .update({ enabled: newStatus })
      .eq("id", id);

    if (error) {
      alert("Failed to update language status.");
      console.error(error);
    } else {
      fetchLanguages();
    }
  };

  const handleDeleteLanguage = async (id: string) => {
    const confirmed = window.confirm(
      "Are you sure you want to delete this language?"
    );
    if (!confirmed) return;

    const { error } = await supabase.from("languages").delete().eq("id", id);

    if (error) {
      alert("Failed to delete language.");
      console.error(error);
    } else {
      fetchLanguages();
    }
  };

  const handleCSVUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = async (event) => {
      const text = event.target?.result as string;
      const lines = text.trim().split("\n");

      const rows = lines.slice(1).map((line) => {
        const [code, label, script, enabled] = line.split(",");
        return {
          code: code.trim(),
          label: label.trim(),
          script: script.trim(),
          enabled: enabled.trim().toLowerCase() === "true",
        };
      });

      // Fetch existing codes
      const { data: existing, error: fetchError } = await supabase
        .from("languages")
        .select("code");

      if (fetchError) {
        alert(" Failed to fetch existing language codes.");
        console.error(fetchError);
        return;
      }

      const existingCodes = new Set(
        (existing || []).map((lang) => lang.code.toLowerCase())
      );
      const newEntries = rows.filter(
        (entry) => !existingCodes.has(entry.code.toLowerCase())
      );

      if (newEntries.length === 0) {
        alert("All languages in this CSV already exist. Nothing to add.");
        return;
      }

      const { error: insertError } = await supabase.from("languages").insert(
        newEntries
      );
      if (insertError) {
        alert(" Failed to insert new languages.");
        console.error(insertError);
      } else {
        alert( ${newEntries.length} added, ${rows.length - newEntries.length} skipped.`);
        fetchLanguages();
      }
    };

    reader.readAsText(file);
  };

  return (
    <div className="p-4">
      <h2 className="text-2xl font-bold text-blue-700 mb-4">Language Management</h2>

      <div className="flex flex-wrap gap-2 mb-4">
        <input
          value={newCode}
          onChange={(e) => setNewCode(e.target.value)}
          placeholder="Code (e.g., ta)"
          className="p-2 border rounded w-40"
        />
        <input
          value={newLabel}
          onChange={(e) => setNewLabel(e.target.value)}
          placeholder="Label (e.g., Tamil)"
          className="p-2 border rounded w-40"
        />
        <input
          value={newScript}
          onChange={(e) => setNewScript(e.target.value)}
          placeholder="Script (e.g., Tamil)"
          className="p-2 border rounded w-40"
        />
        <button
          onClick={handleAddLanguage}
          className="bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700"
        >
          Add Language
        </button>

        <label className="flex items-center gap-2 cursor-pointer ml-4">
          <UploadCloud size={20} />
          <span className="underline text-blue-600">Upload CSV</span>
          <input
            type="file"
            accept=".csv"
            onChange={handleCSVUpload}
            className="hidden"
          />
        </label>
      </div>

      {error && <p className="text-red-600 mb-4">{error}</p>}

      {loading ? (
        <p>Loading...</p>
      ) : (
        <table className="min-w-full border border-gray-300 rounded-lg">
          <thead>
            <tr className="bg-gray-100 text-center">
              <th className="p-2 border">Code</th>
              <th className="p-2 border">Label</th>
              <th className="p-2 border">Script</th>
              <th className="p-2 border">Enabled</th>
              <th className="p-2 border">Delete</th>
            </tr>
          </thead>
          <tbody>
            {languages.map((lang) => (
              <tr key={lang.id} className="text-center">
                <td className="p-2 border">{lang.code}</td>
                <td className="p-2 border">{lang.label}</td>
                <td className="p-2 border">{lang.script}</td>
                <td className="p-2 border">
                  <input
                    type="checkbox"
                    checked={lang.enabled}
                    onChange={() => handleToggleEnabled(lang.id, !lang.enabled)}
                    className="cursor-pointer accent-green-600"
                  />
                </td>
                <td className="p-2 border">
                  <button
                    onClick={() => handleDeleteLanguage(lang.id)}
                    className="text-red-600 hover:text-red-800"
                    title="Delete"
                  >
                    <Trash2 size={18} />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}

