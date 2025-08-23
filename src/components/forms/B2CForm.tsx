"use client";

import { useState } from "react";

export default function B2CForm() {
  const [products, setProducts] = useState([{ name: "", desc: "", mrp: "", price: "", available: false }]);

  const handleAddRow = () => {
    if (products.length < 50) {
      setProducts([...products, { name: "", desc: "", mrp: "", price: "", available: false }]);
    }
  };

  const updateProduct = (index: number, key: string, value: any) => {
    const updated = [...products];
    updated[index][key] = value;
    setProducts(updated);

    if (index === products.length - 1 && products.length < 50) {
      handleAddRow(); // auto-add next row
    }
  };

  return (
    <form className="w-full max-w-3xl mx-auto bg-white p-4 rounded shadow-md overflow-y-auto">
      <h2 className="text-xl font-bold mb-4 text-center">B2C Connector Onboarding</h2>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <input type="text" placeholder="Connector Mobile No" className="input" />
        <input type="text" placeholder="Alternate Mobile No" className="input" />
        <input type="text" placeholder="GST No" className="input" />
        <input type="text" placeholder="Company Name" className="input" />
        <input type="text" placeholder="Short Company Name (â‰¤ 10 char)" className="input" />
        <input type="text" placeholder="Classification (e.g., Super Market)" className="input" />
        <input type="text" placeholder="Address Line 1" className="input" />
        <input type="text" placeholder="City" className="input" />
        <input type="text" placeholder="Pincode" className="input" />
        <input type="email" placeholder="Email ID" className="input" />
        <input type="text" placeholder="Recovery Mobile No" className="input" />
        <input type="text" placeholder="Connecta ID (Auto)" className="input" disabled />
        <input type="text" placeholder="Homepage Image Link" className="input" />
        <input type="text" placeholder="Subscription (auto fill waived)" className="input" value="Rs. 5999/- WAIVED FOR FIRST YEAR" readOnly />
        <input type="text" placeholder="Website URL" className="input" />
        <input type="text" placeholder="Facebook" className="input" />
        <input type="text" placeholder="Instagram" className="input" />
        <input type="text" placeholder="YouTube Shorts" className="input" />
        <input type="text" placeholder="YouTube" className="input" />
        <input type="text" placeholder="Other Links" className="input" />
        <textarea placeholder="Products and Services Offered" className="input col-span-2" />
        <input type="text" placeholder="Location (Google Maps Link)" className="input col-span-2" />
        <input type="number" placeholder="Discount % (Triggers Commission Split)" className="input col-span-2" />
      </div>

      <h3 className="text-lg mt-6 font-semibold">Product List (Max 50)</h3>
      <div className="space-y-2 max-h-96 overflow-y-scroll border p-2 rounded">
        {products.map((product, index) => (
          <div key={index} className="grid grid-cols-5 gap-2 items-center">
            <input
              type="text"
              placeholder={`Product ${index + 1} Name`}
              className="input"
              value={product.name}
              onChange={(e) => updateProduct(index, "name", e.target.value)}
            />
            <input
              type="text"
              placeholder="Description"
              className="input"
              value={product.desc}
              onChange={(e) => updateProduct(index, "desc", e.target.value)}
            />
            <input
              type="number"
              placeholder="MRP"
              className="input"
              value={product.mrp}
              onChange={(e) => updateProduct(index, "mrp", e.target.value)}
            />
            <input
              type="number"
              placeholder="Price"
              className="input"
              value={product.price}
              onChange={(e) => updateProduct(index, "price", e.target.value)}
            />
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={product.available}
                onChange={(e) => updateProduct(index, "available", e.target.checked)}
              />
              Available
            </label>
          </div>
        ))}
      </div>

      <div className="mt-6 flex justify-center">
        <button type="submit" className="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700 transition">
          Submit B2C Details
        </button>
      </div>
    </form>
  );
}

