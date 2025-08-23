"use client";

import { useEffect, useState } from "react";
import { createClient } from "@supabase/supabase-js";

// âœ… Supabase config
const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

interface Language {
  id: string;
  code: string;
  label: string;
  script: string;
  enabled: boolean;
  created_at: string;
}

export default function LanguageManagement() {
  const [languages, setLanguages] = useState<Language[]>([]);
  const [loading, setLoading] = useState(true);

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
      console.error("âŒ Error fetching languages:", error.message);
    } else {
      setLanguages(data as Language[]);
    }

    setLoading(false);
  };

  const handleToggleEnabled = async (id: string, newStatus: boolean) => {
    const { error } = await supabase
      .from("languages")
      .update({ enabled: newStatus })
      .eq("id", id);

    if (error) {
      alert("âŒ Failed to update language status.");
      console.error(error);
    } else {
      fetchLanguages(); // Refresh after update
    }
  };

  return (
    <div className="p-4">
      <h2 className="text-2xl font-bold mb-4 text-blue-700">
        ðŸŒ Language Management
      </h2>

      {loading ? (
        <p>Loading languages...</p>
      ) : (
        <table className="min-w-full border border-gray-300 rounded-lg">
          <thead>
            <tr className="bg-gray-100 text-center">
              <th className="p-2 border">Code</th>
              <th className="p-2 border">Label</th>
              <th className="p-2 border">Script</th>
              <th className="p-2 border">Enabled</th>
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
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}

