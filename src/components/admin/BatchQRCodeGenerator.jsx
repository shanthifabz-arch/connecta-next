"use client";

import React, { useState, useEffect } from "react";
import QRCode from "qrcode";
import JSZip from "jszip";
import { supabase } from "@/lib/supabaseClient";

const QR_SIZE = 200;

// QR generation with two-line text in the middle of QR code (no logo)
async function generateQRCodeWithTwoLineText(text, infoText, size = QR_SIZE) {
  return new Promise(async (resolve, reject) => {
    try {
      const canvas = document.createElement("canvas");
      canvas.width = size;
      canvas.height = size;
      const ctx = canvas.getContext("2d");

      // Draw the QR code
      await QRCode.toCanvas(canvas, text, {
        errorCorrectionLevel: "H",
        margin: 1,
        width: size,
      });

      // Setup text style
      ctx.font = "bold 16px Arial";
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";

      // Bigger rectangle behind text
      const rectWidth = size * 0.95;
      const rectHeight = 70;
      const rectX = (size - rectWidth) / 2;
      const rectY = (size - rectHeight) / 2;

      // Draw semi-transparent white rectangle in the center for text background
      ctx.fillStyle = "rgba(255, 255, 255, 0.85)";
      ctx.fillRect(rectX, rectY, rectWidth, rectHeight);

      // Split infoText into exactly two lines (split by '|')
      const lines = infoText.split("|").map(line => line.trim());

      // Reduced line height for tighter spacing
      const lineHeight = 16;
      const totalTextHeight = lineHeight * lines.length;
      const startY = size / 2 - totalTextHeight / 2 + lineHeight / 2;

      // Draw the two lines with reduced spacing
      lines.forEach((line, i) => {
        ctx.fillStyle = "black";
        ctx.fillText(line, size / 2, startY + i * lineHeight);
      });

      resolve(canvas.toDataURL("image/png"));
    } catch (err) {
      reject(err);
    }
  });
}

export default function BatchQRCodeGenerator() {
  const [language, setLanguage] = useState("");
  const [country, setCountry] = useState("");
  const [state, setState] = useState("");
  const [dateTag, setDateTag] = useState("");
  const [qrCodes, setQrCodes] = useState([]);
  const [loading, setLoading] = useState(false);

  const [languages, setLanguages] = useState([]);
  const [countryStateData, setCountryStateData] = useState({});
  const [countries, setCountries] = useState([]);

  useEffect(() => {
    async function fetchData() {
      let { data: langs, error: langError } = await supabase
        .from("languages")
        .select("label")
        .eq("enabled", true)
        .order("label");

      if (langError) {
        console.error("Error fetching languages:", langError);
      } else {
        const uniqueLangLabels = [...new Set(langs.map((l) => l.label))];
        setLanguages(uniqueLangLabels);
      }

      let { data: csData, error: csError } = await supabase
        .from("country_states")
        .select("country, states");

      if (csError) {
        console.error("Error fetching country_states:", csError);
      } else {
        const grouped = {};
        csData.forEach(({ country, states }) => {
          grouped[country] = states.map((s) => s.name);
        });
        setCountryStateData(grouped);
        setCountries(Object.keys(grouped));
      }
    }
    fetchData();
  }, []);

  useEffect(() => {
    setState("");
  }, [country]);

  const handleGenerate = async () => {
    if (!language || !state || !country || !dateTag) {
      alert("Please fill in all fields.");
      return;
    }
    setLoading(true);

    try {
      const url = `https://connecta.app?lang=${encodeURIComponent(
        language
      )}&state=${encodeURIComponent(state)}&country=${encodeURIComponent(
        country
      )}&date=${encodeURIComponent(dateTag)}`;

      // Format info into two lines separated by '|'
      // Line 1: Language + Date
      // Line 2: State + Country
      const tags = `${language} | ${dateTag} | ${state} | ${country}`;

      const qrDataUrl = await generateQRCodeWithTwoLineText(url, tags, QR_SIZE);

      setQrCodes([{ id: 1, dataUrl: qrDataUrl, tags }]);
    } catch (err) {
      alert("Failed to generate QR codes: " + err.message);
    }
    setLoading(false);
  };

  const handleDownloadSingle = (dataUrl, tags) => {
    const link = document.createElement("a");
    link.href = dataUrl;
    const safeTags = tags.replace(/\s*\|\s*/g, "_").replace(/[^a-zA-Z0-9_-]/g, "");
    link.download = `qr_${safeTags}.png`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const handleDownloadZip = async () => {
    if (qrCodes.length === 0) {
      alert("No QR codes to download.");
      return;
    }
    setLoading(true);
    try {
      const zip = new JSZip();

      for (const { dataUrl, tags, id } of qrCodes) {
        const base64 = dataUrl.split(",")[1];
        const safeTags = tags.replace(/\s*\|\s*/g, "_").replace(/[^a-zA-Z0-9_-]/g, "");
        zip.file(`qr_${id}_${safeTags}.png`, base64, { base64: true });
      }

      const content = await zip.generateAsync({ type: "blob" });
      const link = document.createElement("a");
      link.href = URL.createObjectURL(content);
      link.download = `connecta_batch_qr_${Date.now()}.zip`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    } catch (err) {
      alert("Failed to create ZIP: " + err.message);
    }
    setLoading(false);
  };

  return (
    <div style={{ padding: 20 }}>
      <h2>Batch QR Code Generator - Admin (Text in Middle, Reduced Spacing)</h2>

      <div
        style={{
          marginBottom: 20,
          display: "flex",
          gap: 15,
          flexWrap: "wrap",
          alignItems: "center",
        }}
      >
        <label>
          Language:
          <select
            value={language}
            onChange={(e) => setLanguage(e.target.value)}
            style={{ marginLeft: 8, minWidth: 150 }}
          >
            <option value="">Select Language</option>
            {languages.map((lang) => (
              <option key={lang} value={lang}>
                {lang}
              </option>
            ))}
          </select>
        </label>

        <label>
          Country:
          <select
            value={country}
            onChange={(e) => setCountry(e.target.value)}
            style={{ marginLeft: 8, minWidth: 150 }}
          >
            <option value="">Select Country</option>
            {countries.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>
        </label>

        <label>
          State:
          <select
            value={state}
            onChange={(e) => setState(e.target.value)}
            style={{ marginLeft: 8, minWidth: 150 }}
            disabled={!country}
          >
            <option value="">Select State</option>
            {country &&
              countryStateData[country]?.map((st) => (
                <option key={st} value={st}>
                  {st}
                </option>
              ))}
          </select>
        </label>

        <label>
          Date Tag:
          <input
            type="text"
            value={dateTag}
            onChange={(e) => setDateTag(e.target.value)}
            placeholder="e.g., 0825"
            maxLength={10}
            style={{ marginLeft: 8, minWidth: 100 }}
          />
        </label>

        <button
          onClick={handleGenerate}
          disabled={loading}
          style={{ padding: "6px 12px", height: 32 }}
        >
          {loading ? "Generating..." : "Generate Preview"}
        </button>
      </div>

      <div style={{ display: "flex", flexWrap: "wrap", gap: 20 }}>
        {qrCodes.map(({ id, dataUrl, tags }) => (
          <div key={id} style={{ textAlign: "center" }}>
            <img
              src={dataUrl}
              alt="QR Code"
              style={{ width: QR_SIZE, height: QR_SIZE, border: "1px solid #ccc" }}
            />
            <div style={{ marginTop: 8, fontWeight: "bold" }}>{tags}</div>
            <button
              onClick={() => handleDownloadSingle(dataUrl, tags)}
              style={{ marginTop: 8, padding: "4px 10px" }}
            >
              Download PNG
            </button>
          </div>
        ))}
      </div>

      {qrCodes.length > 0 && (
        <button
          onClick={handleDownloadZip}
          disabled={loading}
          style={{ marginTop: 30, padding: "8px 16px" }}
        >
          Download All as ZIP
        </button>
      )}
    </div>
  );
}

