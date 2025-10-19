"use client";

import { useState } from "react";

interface Service {
  title: string;
  description: string;
  pricing: string;
  available: boolean;
}


export default function B2BForm() {
 const [services, setServices] = useState<Service[]>([
  { title: "", description: "", pricing: "", available: false }
]);


  const addService = () => {
    if (services.length < 50) {
      setServices([...services, { title: "", description: "", pricing: "", available: false }]);
    }
  };

 const updateService = <K extends keyof Service>(index: number, key: K, value: Service[K]) => {
  const updated = [...services];
  updated[index][key] = value;
  setServices(updated);

  if (index === services.length - 1 && services.length < 50) {
    addService(); // auto-add next row
  }
};


  return (
    <form className="w-full max-w-3xl mx-auto bg-white p-4 rounded shadow-md overflow-y-auto">
      <h2 className="text-xl font-bold mb-4 text-center">B2B Connector Onboarding</h2>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <input type="text" placeholder="Connector Mobile No" className="input" />
        <input type="text" placeholder="Alternate Mobile No" className="input" />
        <input type="text" placeholder="GST No" className="input" />
        <input type="text" placeholder="Company/Organization Name" className="input" />
       <input type="text" placeholder="Short Name (≤ 10 characters)" className="input" />
        <input type="text" placeholder="Industry Classification" className="input" />
        <input type="text" placeholder="Head Office Address" className="input" />
        <input type="text" placeholder="City" className="input" />
        <input type="text" placeholder="Pincode" className="input" />
        <input type="email" placeholder="Email ID" className="input" />
        <input type="text" placeholder="Recovery Mobile No" className="input" />
        <input type="text" placeholder="Connecta ID (Auto)" className="input" disabled />
        <input type="text" placeholder="Logo Image Link" className="input" />
        <input type="text" placeholder="Annual Subscription (Auto)" className="input" value="Rs. 9999/- WAIVED FIRST YEAR" readOnly />
        <input type="text" placeholder="Website URL" className="input" />
        <input type="text" placeholder="LinkedIn" className="input" />
        <input type="text" placeholder="Twitter" className="input" />
        <input type="text" placeholder="YouTube" className="input" />
        <textarea placeholder="Business Overview / Capabilities" className="input col-span-2" />
        <input type="text" placeholder="Location Map Link" className="input col-span-2" />
        <input type="number" placeholder="Discount % (for B2B Contracts)" className="input col-span-2" />
      </div>

      <h3 className="text-lg mt-6 font-semibold">Service List (Max 50)</h3>
      <div className="space-y-2 max-h-96 overflow-y-scroll border p-2 rounded">
        {services.map((srv, index) => (
          <div key={index} className="grid grid-cols-4 gap-2 items-center">
            <input
              type="text"
              placeholder={`Service ${index + 1} Title`}
              className="input"
              value={srv.title}
              onChange={(e) => updateService(index, "title", e.target.value)}
            />
            <input
              type="text"
              placeholder="Description"
              className="input"
              value={srv.description}
              onChange={(e) => updateService(index, "description", e.target.value)}
            />
            <input
              type="text"
              placeholder="Pricing / Quote"
              className="input"
              value={srv.pricing}
              onChange={(e) => updateService(index, "pricing", e.target.value)}
            />
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={srv.available}
                onChange={(e) => updateService(index, "available", e.target.checked)}
              />
              Available
            </label>
          </div>
        ))}
      </div>

      <div className="mt-6 flex justify-center">
        <button type="submit" className="bg-green-600 text-white px-6 py-2 rounded hover:bg-green-700 transition">
          Submit B2B Details
        </button>
      </div>
    </form>
  );
}

