"use client";

import { useEffect, useRef, useState } from "react";
import { supabase } from "@/lib/supabaseClient";

type LangOption = { code: string; display_name: string };

export default function LanguagePicker({
  selectedLanguage,
  onSelect,
}: {
  selectedLanguage: string;
  onSelect: (code: string) => void;
}) {
  const [options, setOptions] = useState<LangOption[]>([]);
  const [input, setInput] = useState("");
  const fetchedRef = useRef(false);

  // one-time fetch from translations (code + display_name)
  useEffect(() => {
    if (fetchedRef.current) return;
    fetchedRef.current = true;

    (async () => {
      const { data, error } = await supabase
        .from("translations")
        .select("language_iso_code, display_name");

      if (error) {
        console.error("translations fetch failed:", error.message);
        return;
      }

      // normalize + de-dupe by code and name
      const norm = (data || [])
        .map((r: any) => ({
          code: String(r.language_iso_code || "").trim(),
          display_name: String(r.display_name || "").trim(),
        }))
        .filter(x => x.code && x.display_name);

      const byCode = new Map<string, LangOption>();
      for (const l of norm) {
        const k = l.code.toLowerCase();
        if (!byCode.has(k)) byCode.set(k, l);
      }
      const codeDeduped = Array.from(byCode.values());

      const byName = new Map<string, LangOption>();
      for (const l of codeDeduped) {
        const k = l.display_name.toLowerCase();
        if (!byName.has(k)) byName.set(k, l);
      }
      const final = Array.from(byName.values()).sort((a, b) =>
        a.display_name.localeCompare(b.display_name)
      );

      setOptions(final);
    })();
  }, []);

  // keep textbox showing the pretty name for selectedLanguage
  useEffect(() => {
    const match = options.find(o => o.code === selectedLanguage);
    setInput(match ? match.display_name : "");
  }, [selectedLanguage, options]);

  const filtered = options.filter(o => {
    const q = input.trim().toLowerCase();
    if (!q) return true;
    return (
      o.display_name.toLowerCase().includes(q) ||
      o.code.toLowerCase().includes(q)
    );
  });

  return (
    <div className="mb-4 w-full text-center">
      <label htmlFor="language" className="block mb-1 text-lg font-medium text-gray-800">
        Select Language
      </label>

      <input
        id="language"
        autoComplete="off"
        list="languageListWelcome"
        value={input}
        onChange={(e) => {
          const val = e.target.value.trim();
          setInput(val);

          const byCode = options.find(o => o.code.toLowerCase() === val.toLowerCase());
          const byName = options.find(o => o.display_name.toLowerCase() === val.toLowerCase());

          // also support selecting "English (en)" from the list
          const m = val.match(/\(([^)]+)\)\s*$/);
          const codeFromParens = m?.[1];

          const picked = byCode || byName || options.find(o => o.code === codeFromParens);
          if (picked) onSelect(picked.code);
        }}
        onBlur={() => {
          const match = options.find(o => o.code === selectedLanguage);
          setInput(match ? match.display_name : "");
        }}
        placeholder='Type to filter… try "en"'
        className="border border-gray-400 p-3 rounded-lg w-full bg-white text-black"
      />

      <datalist id="languageListWelcome">
        {filtered.map(o => (
          <option key={o.code} value={`${o.display_name} (${o.code})`} />
        ))}
      </datalist>
    </div>
  );
}
