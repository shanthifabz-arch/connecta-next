"use client";

import { useState } from "react";
import AAConnectorList from "@/components/admin/AAConnectorUpload";

export default function AdminPanelPage() {
  const [activeTab, setActiveTab] = useState("AA Connector List");

  const tabs = [
    "AA Connector List",
    "Language Management",
    "Vendor/Connector Approval",
    "Add New Language",
    "Excel â†' JSON Tool",
    "Other Utilities",
  ];

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <h1 className="text-3xl font-bold text-center text-blue-600 mb-8">
        CONNECTA ADMIN PANEL
      </h1>

      <div className="flex flex-wrap justify-center gap-4 mb-6">
        {tabs.map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`px-4 py-2 rounded ${
              activeTab === tab
                ? "bg-blue-600 text-white"
                : "bg-white border border-gray-300 text-gray-700 hover:bg-blue-100"
            }`}
          >
            {tab}
          </button>
        ))}
      </div>

      {/* Tab content */}
      {activeTab === "AA Connector List" && <AAConnectorList />}

      {activeTab === "Language Management" && (
        <div className="text-center text-gray-600">Coming soon: Language Management</div>
      )}
      {activeTab === "Vendor/Connector Approval" && (
        <div className="text-center text-gray-600">Coming soon: Vendor/Connector Approval</div>
      )}
      {activeTab === "Add New Language" && (
        <div className="text-center text-gray-600">Coming soon: Add New Language</div>
      )}
      {activeTab === "Excel â†' JSON Tool" && (
        <div className="text-center text-gray-600">Coming soon: Excel â†' JSON Tool</div>
      )}
      {activeTab === "Other Utilities" && (
        <div className="text-center text-gray-600">Coming soon: Other Utilities</div>
      )}
    </div>
  );
}

