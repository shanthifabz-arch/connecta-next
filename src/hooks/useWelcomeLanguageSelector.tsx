"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabaseClient";

function useWelcomeLanguageSelector() {
  const router = useRouter();
  const [languageOptions, setLanguageOptions] = useState<any[]>([]);
  const [selectedLang, setSelectedLang] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [showDropdown, setShowDropdown] = useState(false);

  const browserLangs =
    typeof navigator !== "undefined"
      ? navigator.languages?.map((l) => l.split("-")[0]) || []
      : [];

  const getFlagUrl = (countryCode: string) => {
    return `https://flagcdn.com/24x18/${countryCode?.toLowerCase()}.png`;
  };

  useEffect(() => {
    const fetchLanguages = async () => {
      const { data: langs, error } = await supabase
        .from("languages")
        .select("code, label, label_native, country_code")
        .eq("enabled", true);

      if (error) {
        console.error("Error fetching languages:", error);
        setLoading(false);
        return;
      }

      const formattedLangs = langs.map((lang) => {
        const label = lang.label || lang.code;
        const native = lang.label_native || "";
        return {
          ...lang,
          display_name: `${label}${native ? ` (${native})` : ""}`,
          language_code: lang.code,
        };
      });

      const sorted = formattedLangs.sort((a, b) => {
        const aIndex = browserLangs.indexOf(a.language_code?.split("-")[0]);
        const bIndex = browserLangs.indexOf(b.language_code?.split("-")[0]);
        if (aIndex === bIndex) {
          return a.display_name.localeCompare(b.display_name);
        }
        return (aIndex === -1 ? 999 : aIndex) - (bIndex === -1 ? 999 : bIndex);
      });

      setLanguageOptions(sorted);
      setSelectedLang(sorted[0]);
      setLoading(false);
    };

    fetchLanguages();
  }, []);

  const handleSelect = (lang: any) => {
    setSelectedLang(lang);
    setShowDropdown(false);
  };

  const handleContinue = () => {
    if (selectedLang?.language_code) {
      localStorage.setItem("connecta_languages", JSON.stringify(languageOptions));
      router.push(
        `/onboarding-tabs?lang=${selectedLang.language_code}&langLabel=${encodeURIComponent(
          selectedLang.display_name
        )}`
      );
    }
  };

  const renderDropdown = () => (
    <div className="relative">
      <button
        onClick={() => setShowDropdown(!showDropdown)}
        className="w-64 px-4 py-2 border rounded flex justify-between items-center"
      >
        <span className="flex items-center">
          {selectedLang && (
            <img
              src={getFlagUrl(selectedLang.country_code)}
              alt={selectedLang.code}
              className="w-5 h-4 mr-2"
            />
          )}
          {selectedLang?.display_name}
        </span>
        <span>â-¼</span>
      </button>

      {showDropdown && (
        <div className="absolute z-10 w-64 bg-white border rounded mt-1 max-h-60 overflow-y-auto shadow">
          {languageOptions.map((lang) => (
            <div
              key={lang.language_code}
              onClick={() => handleSelect(lang)}
              className="px-4 py-2 hover:bg-gray-100 cursor-pointer flex items-center"
            >
              <img
                src={getFlagUrl(lang.country_code)}
                alt={lang.code}
                className="w-5 h-4 mr-2"
              />
              <span>{lang.display_name}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );

  return {
    languageOptions,
    selectedLang,
    loading,
    handleSelect,
    handleContinue,
    renderDropdown,
  };
}

export default useWelcomeLanguageSelector;

