"use client";

import { useEffect, useState } from "react";
import AAConnectorUpload from "@/components/admin/AAConnectorUpload";
import CountryStateManager from "@/components/admin/CountryStateManager";
import LanguageManager from "@/components/admin/LanguageManager";
import TranslationUpload from "@/components/admin/TranslationUpload";
import TranslationViewer from "@/components/admin/TranslationViewer";
import TranslationEditor from "@/components/admin/TranslationEditor";
import BatchQRCodeGenerator from "@/components/admin/BatchQRCodeGenerator";
// import VendorApproval from "@/components/admin/VendorApproval";

export default function AdminPanelPage() {
  const [activeTab, setActiveTab] = useState("AA Connector List");
  const [isHydrated, setIsHydrated] = useState(false);

  const tabs = [
    { label: "AA Connector List", disabled: false },
    { label: "Country & State Upload", disabled: false },
    { label: "Language Management", disabled: false },
    { label: "Upload JSON", disabled: true },
    { label: "Read-only Viewer", disabled: false },
    { label: "Live Table Editor", disabled: false },
    { label: "Batch QR Code Generator", disabled: false },
    { label: "Vendor/Connector Approval", disabled: true },
    { label: "Add New Language", disabled: true },
    { label: "Excel â†' JSON Tool", disabled: true },
    { label: "Other Utilities", disabled: true }
  ];

  useEffect(() => {
    setIsHydrated(true);
  }, []);

  return (
    <div className="min-h-screen bg-white text-gray-800 p-6">
      <h1 className="text-2xl font-bold text-center mb-6">
        CONNECTA ADMIN PANEL
      </h1>

      <div className="flex flex-wrap justify-center gap-4 mb-6">
        {tabs.map(({ label, disabled }) => (
          <button
            key={label}
            onClick={() => !disabled && setActiveTab(label)}
            disabled={disabled}
            className={`px-4 py-2 rounded font-semibold transition ${
              activeTab === label
                ? "bg-blue-600 text-white border border-blue-700"
                : disabled
                ? "bg-gray-200 text-gray-400 border border-gray-300 cursor-not-allowed"
                : "bg-white text-blue-700 border border-blue-700 hover:bg-blue-100"
            }`}
          >
            {label}
          </button>
        ))}
      </div>

      <div>
        {isHydrated && activeTab === "AA Connector List" && <AAConnectorUpload />}
        {isHydrated && activeTab === "Country & State Upload" && <CountryStateManager />}
        {isHydrated && activeTab === "Language Management" && <LanguageManager />}
        {isHydrated && activeTab === "Upload JSON" && <TranslationUpload />}
        {isHydrated && activeTab === "Read-only Viewer" && <TranslationViewer />}
        {isHydrated && activeTab === "Live Table Editor" && <TranslationEditor />}
        {isHydrated && activeTab === "Batch QR Code Generator" && <BatchQRCodeGenerator />}
        {/* {isHydrated && activeTab === "Vendor/Connector Approval" && <VendorApproval />} */}
      </div>
    </div>
  );
}

