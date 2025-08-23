"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabaseClient";
import Papa from "papaparse";

export default function AAConnectorUpload() {
  const [connectors, setConnectors] = useState<any[]>([]);
  const [filtered, setFiltered] = useState<any[]>([]);
  const [searchTerm, setSearchTerm] = useState("");

  const [selectedCountry, setSelectedCountry] = useState("");
  const [selectedState, setSelectedState] = useState("");
  const [selectedLanguage, setSelectedLanguage] = useState("");

  const [csvFile, setCsvFile] = useState<File | null>(null);
  const [csvSuccess, setCsvSuccess] = useState("");
  const [uploading, setUploading] = useState(false);
  const [skippedNumbers, setSkippedNumbers] = useState<string[]>([]);
  const [formatErrors, setFormatErrors] = useState<string[]>([]);

  // New state for single mobile add
  const [singleMobile, setSingleMobile] = useState("");
  // Optional: single aa_joining_code input (add if needed)
  // const [singleAAJoiningCode, setSingleAAJoiningCode] = useState("");

  // Dynamic country -> states map and language options
  const [countryStateData, setCountryStateData] = useState<{ [country: string]: string[] }>({});
  const [languageOptions, setLanguageOptions] = useState<string[]>([]);

  // Fetch AA connectors
  const fetchConnectors = async () => {
    const { data, error } = await supabase
      .from("aa_connectors")
      .select("*")
      .order("created_at", { ascending: false });
    if (error) {
      console.error("Error fetching connectors:", error);
      return;
    }
    setConnectors(data || []);
    setFiltered(data || []);
  };

  // Fetch country states and languages from Supabase
  useEffect(() => {
    fetchConnectors();

    async function fetchCountryStates() {
      const { data, error } = await supabase
        .from("country_states")
        .select("country, states");
      if (error) {
        console.error("Error fetching country_states:", error);
        return;
      }
      const grouped: { [key: string]: string[] } = {};
      data.forEach(({ country, states }: any) => {
        grouped[country] = states.map((s: any) => s.name);
      });
      setCountryStateData(grouped);
    }

    async function fetchLanguages() {
      const { data, error } = await supabase
        .from("languages")
        .select("label")
        .eq("enabled", true)
        .order("label");
      if (error) {
        console.error("Error fetching languages:", error);
        return;
      }
      const uniqueLabels = Array.from(new Set(data.map((item: any) => item.label)));
      setLanguageOptions(uniqueLabels);
    }

    fetchCountryStates();
    fetchLanguages();
  }, []);

  // Filter connectors on search term
  useEffect(() => {
    let temp = connectors;
    if (searchTerm) temp = temp.filter((c) => c.mobile.includes(searchTerm));
    setFiltered(temp);
  }, [searchTerm, connectors]);

  // Delete a connector by id
  const handleDelete = async (id: number) => {
    const confirm = window.confirm("Are you sure you want to delete this connector?");
    if (!confirm) return;
    const { error } = await supabase.from("aa_connectors").delete().eq("id", id);
    if (error) {
      alert("Failed to delete.");
      return;
    }
    setConnectors((prev) => prev.filter((c) => c.id !== id));
  };

  // Download CSV template with full columns and example including aa_joining_code
  const handleTemplateDownload = () => {
    const headers = ["mobile", "COUNTRY", "STATE", "LANGUAGE", "aa_joining_code"];
    const exampleRow = ["+1234567890", "India", "Tamil Nadu", "Tamil", "AA-IN-TN-20250718"];
    const csvContent = `${headers.join(",")}\n${exampleRow.join(",")}`;
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.setAttribute("download", "aa_connector_template.csv");
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  // Handle CSV upload and insert valid, unique mobile numbers with header validation
  const handleUploadClick = () => {
    if (!csvFile) return;
    if (!selectedCountry || !selectedState || !selectedLanguage) {
      alert("Please select Country, State, and Language before uploading.");
      return;
    }

    setUploading(true);
    setCsvSuccess("");
    setSkippedNumbers([]);
    setFormatErrors([]);

    Papa.parse(csvFile, {
      header: true,
      skipEmptyLines: true,
      complete: async (results: any) => {
        const headerKeys = results.meta.fields || [];

        // Validate required columns present including aa_joining_code
        const requiredHeaders = ["mobile", "COUNTRY", "STATE", "LANGUAGE", "aa_joining_code"];
        const missingHeaders = requiredHeaders.filter(
          (h) => !headerKeys.includes(h)
        );
        if (missingHeaders.length > 0) {
          alert(
            `CSV missing required columns: ${missingHeaders.join(
              ", "
            )}. Please fix and try again.`
          );
          setUploading(false);
          return;
        }

        // Validate rows match selected COUNTRY, STATE, LANGUAGE (case-insensitive)
        const mismatches = results.data.filter(
          (row: any) =>
            row.COUNTRY?.toLowerCase() !== selectedCountry.toLowerCase() ||
            row.STATE?.toLowerCase() !== selectedState.toLowerCase() ||
            row.LANGUAGE?.toLowerCase() !== selectedLanguage.toLowerCase()
        );

        if (mismatches.length > 0) {
          alert(
            `CSV rows contain COUNTRY, STATE or LANGUAGE values that do not match the selected options.\n` +
              `Please fix the CSV to match:\nCOUNTRY = ${selectedCountry}\nSTATE = ${selectedState}\nLANGUAGE = ${selectedLanguage}`
          );
          setUploading(false);
          return;
        }

        // Validate all rows have aa_joining_code and not empty
        const missingCodeRows = results.data.filter(
          (row: any) => !row.aa_joining_code || row.aa_joining_code.trim() === ""
        );
        if (missingCodeRows.length > 0) {
          alert(`Some rows are missing the required 'aa_joining_code' field. Please fill it.`);
          setUploading(false);
          return;
        }

        const rows = results.data;

        const allMobiles = rows
          .map((row: any) => String(row.mobile).trim())
          .filter((mobile: string) => mobile);

        const validMobiles = allMobiles.filter((mobile: string) =>
          /^\+[1-9]\d{9,14}$/.test(mobile)
        );
        const invalidMobiles = allMobiles.filter(
          (mobile: string) => !/^\+[1-9]\d{9,14}$/.test(mobile)
        );

        const { data: existing, error } = await supabase
          .from("aa_connectors")
          .select("mobile")
          .in("mobile", validMobiles);

        if (error) {
          console.error("âŒ Supabase fetch error:", error);
          alert("Error checking duplicates.");
          setUploading(false);
          return;
        }

        const existingMobiles = new Set(existing.map((e: any) => e.mobile));
        const newEntries = rows
          .filter((row: any) => {
            const mobile = String(row.mobile).trim();
            return (
              /^\+[1-9]\d{9,14}$/.test(mobile) &&
              !existingMobiles.has(mobile) &&
              row.aa_joining_code.trim() !== ""
            );
          })
          .map((row: any) => ({
            mobile: String(row.mobile).trim(),
            COUNTRY: selectedCountry,
            STATE: selectedState,
            LANGUAGE: selectedLanguage,
            aa_joining_code: row.aa_joining_code.trim(),
          }));

        const skipped = validMobiles.filter((num: string) => existingMobiles.has(num));

        if (newEntries.length === 0) {
          setCsvSuccess(
            `âŒ No new valid entries. ${skipped.length} duplicates. ${invalidMobiles.length} invalid.`
          );
          setSkippedNumbers(skipped);
          setFormatErrors(invalidMobiles);
          setUploading(false);
          return;
        }

        const { error: insertError } = await supabase
          .from("aa_connectors")
          .insert(newEntries);

        if (insertError) {
          console.error("âŒ Supabase insert error:", insertError);
          alert("Upload failed. Check console for error.");
        } else {
          setCsvSuccess(
            `âœ… Uploaded ${newEntries.length} new connector(s). âŒ Skipped ${skipped.length} duplicate(s). âŒ ${invalidMobiles.length} invalid format.`
          );
          setSkippedNumbers(skipped);
          setFormatErrors(invalidMobiles);
          fetchConnectors();
        }

        setUploading(false);
        setCsvFile(null);
      },
      error: (err) => {
        alert("CSV parsing failed.");
        console.error(err);
        setUploading(false);
      },
    });
  };

  // Handle single mobile add submit (no change needed unless you want aa_joining_code input)
  const handleSingleAdd = async () => {
    const mobileTrimmed = singleMobile.trim();

    if (!mobileTrimmed) {
      alert("Please enter a mobile number.");
      return;
    }
    if (!/^\+[1-9]\d{9,14}$/.test(mobileTrimmed)) {
      alert("Mobile number format invalid. Use E.164 format starting with + and country code.");
      return;
    }
    if (!selectedCountry || !selectedState || !selectedLanguage) {
      alert("Please select Country, State, and Language.");
      return;
    }

    setUploading(true);
    setCsvSuccess("");
    setSkippedNumbers([]);
    setFormatErrors([]);

    // Check if already exists with maybeSingle to avoid 406 errors
    const { data: existing, error: fetchError } = await supabase
      .from("aa_connectors")
      .select("mobile")
      .eq("mobile", mobileTrimmed)
      .limit(1)
      .maybeSingle();

    if (fetchError && fetchError.code !== "PGRST116") {
      alert("Error checking existing mobile.");
      setUploading(false);
      return;
    }
    if (existing) {
      setCsvSuccess(`âŒ Mobile number ${mobileTrimmed} already exists.`);
      setUploading(false);
      return;
    }

    // Insert new record without aa_joining_code here (or add if you want)
    const { error: insertError } = await supabase.from("aa_connectors").insert([
      {
        mobile: mobileTrimmed,
        COUNTRY: selectedCountry,
        STATE: selectedState,
        LANGUAGE: selectedLanguage,
        // aa_joining_code: singleAAJoiningCode || "", // uncomment if you add input
      },
    ]);

    if (insertError) {
      alert("Error inserting mobile. Check console.");
      console.error(insertError);
    } else {
      setCsvSuccess(`âœ… Added mobile number ${mobileTrimmed}.`);
      fetchConnectors();
      setSingleMobile("");
    }

    setUploading(false);
  };

  return (
    <div className="p-6 space-y-4">
      <h2 className="text-xl font-semibold">AA Connector List</h2>

      {/* Single mobile add form */}
      <div className="p-4 border rounded space-y-3 bg-gray-100">
        <h3 className="font-semibold mb-2">Add Single Mobile Number</h3>
        <div className="flex flex-wrap gap-4 items-center">
          <input
            type="text"
            placeholder="+12345678901"
            value={singleMobile}
            onChange={(e) => setSingleMobile(e.target.value)}
            className="border p-2 rounded w-[250px]"
            disabled={uploading}
          />

          <select
            value={selectedCountry}
            onChange={(e) => {
              setSelectedCountry(e.target.value);
              setSelectedState("");
            }}
            className="border p-2 rounded w-[200px]"
            disabled={uploading}
          >
            <option value="">Select Country</option>
            {Object.keys(countryStateData).map((country) => (
              <option key={country} value={country}>
                {country}
              </option>
            ))}
          </select>

          <select
            value={selectedState}
            onChange={(e) => setSelectedState(e.target.value)}
            className="border p-2 rounded w-[200px]"
            disabled={!selectedCountry || uploading}
          >
            <option value="">Select State</option>
            {selectedCountry &&
              countryStateData[selectedCountry]?.map((state) => (
                <option key={state} value={state}>
                  {state}
                </option>
              ))}
          </select>

          <select
            value={selectedLanguage}
            onChange={(e) => setSelectedLanguage(e.target.value)}
            className="border p-2 rounded w-[200px]"
            disabled={uploading}
          >
            <option value="">Select Language</option>
            {languageOptions.map((lang, index) => (
              <option key={index} value={lang}>
                {lang}
              </option>
            ))}
          </select>

          <button
            onClick={handleSingleAdd}
            className="bg-indigo-600 text-white px-4 py-2 rounded hover:bg-indigo-700 disabled:bg-gray-400"
            disabled={uploading}
          >
            Add Mobile
          </button>
        </div>
      </div>

      {/* CSV upload area */}
      <div className="p-4 border rounded space-y-3 bg-gray-50">
        <div className="flex flex-wrap gap-4 items-center">
          <input
            type="file"
            accept=".csv"
            onChange={(e) => setCsvFile(e.target.files?.[0] || null)}
            className="border p-2 rounded w-[250px]"
            disabled={uploading}
          />

          <button
            onClick={handleUploadClick}
            className="bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700 disabled:bg-gray-400"
            disabled={uploading || !csvFile}
          >
            Upload CSV
          </button>

          <button
            onClick={handleTemplateDownload}
            className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
            disabled={uploading}
          >
            Download Template
          </button>
        </div>

        {uploading && <p className="text-blue-500">Uploading...</p>}
        {csvSuccess && (
          <p className="text-green-600 font-medium whitespace-pre-line">{csvSuccess}</p>
        )}

        {skippedNumbers.length > 0 && (
          <div className="text-sm text-red-600 bg-red-50 border border-red-200 rounded p-3 mt-2">
            <p className="font-semibold mb-1">Skipped Duplicate Numbers:</p>
            <div className="flex flex-wrap gap-2">
              {skippedNumbers.map((num, i) => (
                <span
                  key={i}
                  className="bg-white border px-2 py-1 rounded shadow-sm"
                >
                  {num}
                </span>
              ))}
            </div>
          </div>
        )}

        {formatErrors.length > 0 && (
          <div className="text-sm text-orange-600 bg-orange-50 border border-orange-200 rounded p-3 mt-2">
            <p className="font-semibold mb-1">Skipped Invalid Format Numbers:</p>
            <div className="flex flex-wrap gap-2">
              {formatErrors.map((num, i) => (
                <span
                  key={i}
                  className="bg-white border px-2 py-1 rounded shadow-sm"
                >
                  {num}
                </span>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Search and list */}
      <div className="flex flex-wrap gap-4 mt-6">
        <input
          type="text"
          placeholder="Search mobile..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="border p-2 rounded w-[200px]"
        />
      </div>

      <table className="min-w-full text-sm table-auto mt-4">
        <thead className="bg-gray-100">
          <tr>
            <th className="px-3 py-2">#</th>
            <th className="px-3 py-2">Mobile</th>
            <th className="px-3 py-2">Country</th>
            <th className="px-3 py-2">State</th>
            <th className="px-3 py-2">Language</th>
            <th className="px-3 py-2">AA Joining Code</th>
            <th className="px-3 py-2">Created At</th>
            <th className="px-3 py-2">Action</th>
          </tr>
        </thead>
        <tbody>
          {filtered.map((c, index) => (
            <tr key={c.id} className="border-t">
              <td className="px-3 py-2">{index + 1}</td>
              <td className="px-3 py-2">{c.mobile}</td>
              <td className="px-3 py-2">{c.COUNTRY}</td>
              <td className="px-3 py-2">{c.STATE}</td>
              <td className="px-3 py-2">{c.LANGUAGE}</td>
              <td className="px-3 py-2">{c.aa_joining_code || "-"}</td>
              <td className="px-3 py-2">{new Date(c.created_at).toLocaleString()}</td>
              <td className="px-3 py-2">
                <button
                  onClick={() => handleDelete(c.id)}
                  className="bg-red-500 text-white px-2 py-1 rounded hover:bg-red-600"
                >
                  Delete
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

