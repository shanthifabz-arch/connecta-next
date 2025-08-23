"use client";
import React from "react";

export default function DownloadLanguagesCSV() {
  function handleDownload() {
    const csv = `Code,Label,Script,Enabled,Delete
af,Afrikaans,Latin,true,false
sq,Albanian,Latin,true,false
am,Amharic,Ethiopic,true,false
ar,Arabic,Arabic,true,false
...`;  // Your full CSV data here

    const blob = new Blob([csv], { type: "text/csv;charset=utf-8" });
    const url = URL.createObjectURL(blob);

    const a = document.createElement("a");
    a.href = url;
    a.download = "languages_master.csv";
    a.click();

    URL.revokeObjectURL(url);
  }

  return (
    <div>
      <h2>Download Languages CSV</h2>
      <button onClick={handleDownload}>
        Download CSV
      </button>
    </div>
  );
}

