"use client";

import React, { useEffect, useMemo, useRef, useState } from "react";
import { createClient, SupabaseClient } from "@supabase/supabase-js";

/** Types **/
type Availability = "open" | "paused";
export type Merchant = {
  id: string;
  name: string;
  category: string;
  discount_pct: number;
  location: string;
  tags: string[];
  availability: Availability;
  landing_url?: string | null;
  logo_url?: string | null;
  is_deleted: boolean;
  created_at: string;
  updated_at: string;
};

const CATEGORIES = [
  { value: "electronics", label: "Electronics" },
  { value: "fashion", label: "Fashion" },
  { value: "home", label: "Home" },
  { value: "grocery", label: "Grocery" },
  { value: "others", label: "Others" },
];

export default function AdminAffiliatesPage() {
  // Create Supabase client on the client only (may be null if envs are missing)
  const supabase = useMemo<SupabaseClient | null>(() => {
    const url = process.env.NEXT_PUBLIC_SUPABASE_URL as string | undefined;
    const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY as string | undefined;
    if (!url || !key) return null;
    return createClient(url, key);
  }, []);

  const [q, setQ] = useState("");
  const [category, setCategory] = useState<string>("all");
  const [availability, setAvailability] = useState<"all" | Availability>("all");
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [rows, setRows] = useState<Merchant[]>([]);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [logoFile, setLogoFile] = useState<File | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);

  const [form, setForm] = useState({
    name: "",
    category: "electronics",
    discount_pct: 0,
    location: "",
    tagsCsv: "",
    availability: "open" as Availability,
    landing_url: "",
    logo_url: "",
  });

  const filtered = useMemo(() => {
    return rows.filter((r) => {
      if (r.is_deleted) return false;
      if (category !== "all" && r.category !== category) return false;
      if (availability !== "all" && r.availability !== availability) return false;
      if (q) {
        const hay = `${r.name} ${r.location} ${r.category} ${(r.tags || []).join(" ")}`.toLowerCase();
        if (!hay.includes(q.toLowerCase())) return false;
      }
      return true;
    });
  }, [rows, q, category, availability]);

  useEffect(() => {
    void fetchRows();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  if (!supabase) {
    return (
      <div className="space-y-2 p-4 rounded border border-amber-300 bg-amber-50 text-amber-900">
        <div className="font-medium">Affiliates – Admin</div>
        <div className="text-sm">
          Missing <code>NEXT_PUBLIC_SUPABASE_URL</code> or <code>NEXT_PUBLIC_SUPABASE_ANON_KEY</code>.
          Add them to <code>.env.local</code> and restart the dev server.
        </div>
      </div>
    );
  }

  async function fetchRows() {
    setLoading(true);
    const sb = supabase;
    if (!sb) {
      setLoading(false);
      alert("Supabase client not initialized. Please refresh.");
      return;
    }
    const { data, error } = await sb
      .from("affiliates_merchants")
      .select("*")
      .order("created_at", { ascending: false });
    setLoading(false);
    if (error) {
      console.error(error);
      alert(`Failed to load merchants: ${error.message}`);
      return;
    }
    setRows((data || []) as unknown as Merchant[]);
  }

  function validateBasic(f: typeof form) {
    if (!f.name.trim()) return "Name is required";
    if (!f.category) return "Category is required";
    if (f.discount_pct < 0 || f.discount_pct > 90) return "Discount must be 0–90";
    if (f.landing_url && !/^https?:\/\//i.test(f.landing_url)) return "Landing URL must start with http(s)://";
    return null;
  }

  async function uploadLogoIfNeeded(merchantId: string) {
    if (!logoFile) return null;
    const sb = supabase;
    if (!sb) throw new Error("Supabase client not initialized");

    const ext = logoFile.name.split(".").pop() || "png";
    const key = `${merchantId}/${Date.now()}.${ext}`;
    const { error } = await sb.storage.from("affiliates-logos").upload(key, logoFile, {
      cacheControl: "3600",
      upsert: true,
    });
    if (error) throw error;
    const { data } = sb.storage.from("affiliates-logos").getPublicUrl(key);
    return data.publicUrl || null;
  }

  async function createMerchant() {
    const err = validateBasic(form);
    if (err) return alert(err);
    setSaving(true);
    const sb = supabase;
    if (!sb) {
      setSaving(false);
      alert("Supabase client not initialized. Please refresh.");
      return;
    }
    try {
      const payload = {
        name: form.name.trim(),
        category: form.category,
        discount_pct: Number(form.discount_pct) || 0,
        location: form.location.trim(),
        tags: form.tagsCsv.split(",").map((s) => s.trim()).filter(Boolean),
        availability: form.availability,
        landing_url: form.landing_url?.trim() || null,
        logo_url: null as string | null,
      };

      const { data, error } = await sb
        .from("affiliates_merchants")
        .insert(payload)
        .select("*")
        .single();
      if (error) throw error;
      const created = data as unknown as Merchant;

      const logoUrl = await uploadLogoIfNeeded(created.id);
      if (logoUrl) {
        const { error: upErr, data: updated } = await sb
          .from("affiliates_merchants")
          .update({ logo_url: logoUrl })
          .eq("id", created.id)
          .select("*")
          .single();
        if (upErr) throw upErr;
        setRows((prev) => [updated as any, ...prev]);
      } else {
        setRows((prev) => [created, ...prev]);
      }

      setForm({
        name: "",
        category: "electronics",
        discount_pct: 0,
        location: "",
        tagsCsv: "",
        availability: "open",
        landing_url: "",
        logo_url: "",
      });
      setLogoFile(null);
      if (fileInputRef.current) fileInputRef.current.value = "";
    } catch (e: any) {
      console.error(e);
      alert(`Failed to create merchant: ${e.message || e}`);
    } finally {
      setSaving(false);
    }
  }

  async function updateMerchant(id: string, patch: Partial<Merchant>) {
    const sb = supabase;
    if (!sb) {
      alert("Supabase client not initialized. Please refresh.");
      return null;
    }
    const { error, data } = await sb
      .from("affiliates_merchants")
      .update({ ...patch, updated_at: new Date().toISOString() })
      .eq("id", id)
      .select("*")
      .single();
    if (error) {
      console.error(error);
      alert(`Update failed: ${error.message}`);
      return null;
    }
    setRows((prev) => prev.map((r) => (r.id === id ? (data as any) : r)));
    return data as Merchant;
  }

  async function toggleAvailability(r: Merchant) {
    await updateMerchant(r.id, { availability: r.availability === "open" ? "paused" : "open" });
  }

  async function softDelete(r: Merchant) {
    if (!confirm(`Delete ${r.name}?`)) return;
    await updateMerchant(r.id, { is_deleted: true });
  }

  function trackingLinkPreview(r: Merchant) {
    return `/r/${r.id}`;
  }

  function parseCsv(text: string) {
    const lines = text.split(/\r?\n/).filter(Boolean);
    if (!lines.length) return [] as any[];
    const header = lines[0].split(",").map((h) => h.trim());
    const out: any[] = [];
    for (let i = 1; i < lines.length; i++) {
      const cols = lines[i].split(",");
      const row: any = {};
      header.forEach((h, j) => (row[h] = (cols[j] || "").trim()));
      out.push(row);
    }
    return out;
  }

  async function handleCsv(file: File) {
    const text = await file.text();
    const parsed = parseCsv(text);
    if (!parsed.length) return alert("CSV empty or unreadable");

    const payloads = parsed.map((r) => ({
      name: r.name,
      category: r.category || "others",
      discount_pct: Number(r.discountPct) || 0,
      location: r.location || "",
      tags: (r.tags || "").split("|").map((s: string) => s.trim()).filter(Boolean),
      availability: (r.availability || "open").toLowerCase() === "paused" ? "paused" : "open",
      landing_url: r.landingUrl || null,
      logo_url: r.logoUrl || null,
    }));

    const sb = supabase;
    if (!sb) {
      alert("Supabase client not initialized. Please refresh.");
      return;
    }
    const { data, error } = await sb.from("affiliates_merchants").insert(payloads).select("*");
    if (error) {
      console.error(error);
      alert(`CSV import failed: ${error.message}`);
      return;
    }
    setRows((prev) => [...(data as any[]), ...prev]);
    alert(`Imported ${data?.length || 0} merchants.`);
  }

  return (
    <div className="space-y-6">
      <div>
        <div className="text-2xl font-bold">Affiliates – Admin</div>
        <div className="text-sm text-gray-600">
          Create and manage affiliate merchants shown in PostJoin → Online Purchases.
        </div>
      </div>

      {/* Create form */}
      <div className="rounded-lg border">
        <div className="px-4 py-2 border-b bg-gray-50 font-medium">Add Merchant</div>
        <div className="p-4 grid md:grid-cols-3 gap-3">
          <div>
            <label className="block text-xs text-gray-600 mb-1">Name *</label>
            <input
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
              className="w-full border rounded px-2 py-1 text-sm"
            />
          </div>
          <div>
            <label className="block text-xs text-gray-600 mb-1">Category *</label>
            <select
              value={form.category}
              onChange={(e) => setForm({ ...form, category: e.target.value })}
              className="w-full border rounded px-2 py-1 text-sm"
            >
              {CATEGORIES.map((c) => (
                <option key={c.value} value={c.value}>
                  {c.label}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-xs text-gray-600 mb-1">Discount %</label>
            <input
              type="number"
              min={0}
              max={90}
              value={form.discount_pct}
              onChange={(e) =>
                setForm({
                  ...form,
                  discount_pct: Math.max(0, Math.min(90, Number(e.target.value) || 0)),
                })
              }
              className="w-full border rounded px-2 py-1 text-sm"
            />
          </div>
          <div>
            <label className="block text-xs text-gray-600 mb-1">Location</label>
            <input
              value={form.location}
              onChange={(e) => setForm({ ...form, location: e.target.value })}
              className="w-full border rounded px-2 py-1 text-sm"
            />
          </div>
          <div>
            <label className="block text-xs text-gray-600 mb-1">Tags (comma separated)</label>
            <input
              value={form.tagsCsv}
              onChange={(e) => setForm({ ...form, tagsCsv: e.target.value })}
              placeholder="Electronics, Prime, Fast Delivery"
              className="w-full border rounded px-2 py-1 text-sm"
            />
          </div>
          <div>
            <label className="block text-xs text-gray-600 mb-1">Availability</label>
            <select
              value={form.availability}
              onChange={(e) => setForm({ ...form, availability: e.target.value as Availability })}
              className="w-full border rounded px-2 py-1 text-sm"
            >
              <option value="open">Open</option>
              <option value="paused">Paused</option>
            </select>
          </div>
          <div className="md:col-span-2">
            <label className="block text-xs text-gray-600 mb-1">Landing URL</label>
            <input
              value={form.landing_url}
              onChange={(e) => setForm({ ...form, landing_url: e.target.value })}
              placeholder="https://merchant.com/affiliate?ref=..."
              className="w-full border rounded px-2 py-1 text-sm"
            />
          </div>
          <div>
            <label className="block text-xs text-gray-600 mb-1">Logo</label>
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              onChange={(e) => setLogoFile(e.target.files?.[0] || null)}
              className="w-full text-sm"
            />
          </div>
        </div>
        <div className="p-4 border-t flex items-center gap-3">
          <button
            onClick={createMerchant}
            disabled={saving}
            className="px-3 py-1.5 rounded border bg-blue-600 text-white disabled:opacity-60"
          >
            {saving ? "Saving…" : "Add Merchant"}
          </button>
          <div className="ml-auto text-xs text-gray-500">* Required fields</div>
        </div>
      </div>

      {/* Toolbar */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="flex-1 min-w-[200px]">
          <input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Search merchants…"
            className="w-full border rounded px-2 py-1 text-sm"
          />
        </div>
        <select
          value={category}
          onChange={(e) => setCategory(e.target.value)}
          className="border rounded px-2 py-1 text-sm"
        >
          <option value="all">All categories</option>
          {CATEGORIES.map((c) => (
            <option key={c.value} value={c.value}>
              {c.label}
            </option>
          ))}
        </select>
        <select
          value={availability}
          onChange={(e) => setAvailability(e.target.value as any)}
          className="border rounded px-2 py-1 text-sm"
        >
          <option value="all">All statuses</option>
          <option value="open">Open</option>
          <option value="paused">Paused</option>
        </select>
        <label className="flex items-center gap-2 text-sm cursor-pointer">
          <input type="file" accept=".csv" onChange={(e) => e.target.files && handleCsv(e.target.files[0])} />
          <span>Import CSV</span>
        </label>
        <button onClick={fetchRows} disabled={loading} className="px-3 py-1 rounded border text-sm">
          {loading ? "Refreshing…" : "Refresh"}
        </button>
      </div>

      {/* Table */}
      <div className="rounded-lg border overflow-x-auto">
        <table className="min-w-full text-sm">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-3 py-2 text-left">Logo</th>
              <th className="px-3 py-2 text-left">Name</th>
              <th className="px-3 py-2 text-left">Category</th>
              <th className="px-3 py-2 text-right">Disc %</th>
              <th className="px-3 py-2 text-left">Location</th>
              <th className="px-3 py-2 text-left">Tags</th>
              <th className="px-3 py-2 text-left">Availability</th>
              <th className="px-3 py-2 text-left">Landing URL</th>
              <th className="px-3 py-2 text-left">Tracking</th>
              <th className="px-3 py-2 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {filtered.map((r) => (
              <tr key={r.id} className={r.is_deleted ? "opacity-50" : ""}>
                <td className="px-3 py-2">
                  {r.logo_url ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={r.logo_url} alt={r.name} className="w-10 h-10 object-cover rounded" />
                  ) : (
                    <div className="w-10 h-10 rounded bg-gray-200 flex items-center justify-center text-xs">
                      {r.name?.[0] || "?"}
                    </div>
                  )}
                </td>
                <td className="px-3 py-2">
                  {editingId === r.id ? (
                    <input
                      defaultValue={r.name}
                      onBlur={(e) => void updateMerchant(r.id, { name: e.target.value })}
                      className="border rounded px-2 py-1 text-sm w-full"
                    />
                  ) : (
                    <div className="font-medium">{r.name}</div>
                  )}
                </td>
                <td className="px-3 py-2">
                  {editingId === r.id ? (
                    <select
                      defaultValue={r.category}
                      onBlur={(e) => void updateMerchant(r.id, { category: e.target.value })}
                      className="border rounded px-2 py-1 text-sm"
                    >
                      {CATEGORIES.map((c) => (
                        <option key={c.value} value={c.value}>
                          {c.label}
                        </option>
                      ))}
                    </select>
                  ) : (
                    <span className="text-gray-700">{r.category}</span>
                  )}
                </td>
                <td className="px-3 py-2 text-right">
                  {editingId === r.id ? (
                    <input
                      type="number"
                      min={0}
                      max={90}
                      defaultValue={r.discount_pct}
                      onBlur={(e) =>
                        void updateMerchant(r.id, {
                          discount_pct: Math.max(0, Math.min(90, Number(e.target.value) || 0)),
                        })
                      }
                      className="border rounded px-2 py-1 text-sm w-20 text-right"
                    />
                  ) : (
                    <span>{r.discount_pct}%</span>
                  )}
                </td>
                <td className="px-3 py-2">
                  {editingId === r.id ? (
                    <input
                      defaultValue={r.location}
                      onBlur={(e) => void updateMerchant(r.id, { location: e.target.value })}
                      className="border rounded px-2 py-1 text-sm w-full"
                    />
                  ) : (
                    <span>{r.location}</span>
                  )}
                </td>
                <td className="px-3 py-2">
                  {editingId === r.id ? (
                    <input
                      defaultValue={(r.tags || []).join(", ")}
                      onBlur={(e) =>
                        void updateMerchant(r.id, {
                          tags: e.target.value.split(",").map((s) => s.trim()).filter(Boolean),
                        })
                      }
                      className="border rounded px-2 py-1 text-sm w-full"
                    />
                  ) : (
                    <div className="flex flex-wrap gap-1">
                      {(r.tags || []).map((t, i) => (
                        <span key={i} className="text-[11px] px-2 py-0.5 rounded bg-gray-100">
                          {t}
                        </span>
                      ))}
                    </div>
                  )}
                </td>
                <td className="px-3 py-2">
                  <span
                    className={`text-xs px-2 py-0.5 rounded ${
                      r.availability === "open" ? "bg-green-100 text-green-800" : "bg-amber-100 text-amber-800"
                    }`}
                  >
                    {r.availability}
                  </span>
                </td>
                <td className="px-3 py-2 max-w-[240px] truncate">
                  {editingId === r.id ? (
                    <input
                      defaultValue={r.landing_url || ""}
                      onBlur={(e) => void updateMerchant(r.id, { landing_url: e.target.value || null })}
                      className="border rounded px-2 py-1 text-sm w-full"
                    />
                  ) : r.landing_url ? (
                    <a href={r.landing_url} target="_blank" rel="noreferrer" className="text-blue-600 underline">
                      Open
                    </a>
                  ) : (
                    <span className="text-gray-500">—</span>
                  )}
                </td>
                <td className="px-3 py-2">
                  <code className="text-xs">{trackingLinkPreview(r)}</code>
                </td>
                <td className="px-3 py-2 text-right space-x-2 whitespace-nowrap">
                  {editingId === r.id ? (
                    <button onClick={() => setEditingId(null)} className="px-2 py-1 text-sm rounded border">
                      Done
                    </button>
                  ) : (
                    <button onClick={() => setEditingId(r.id)} className="px-2 py-1 text-sm rounded border">
                      Edit
                    </button>
                  )}
                  <button onClick={() => void toggleAvailability(r)} className="px-2 py-1 text-sm rounded border">
                    {r.availability === "open" ? "Pause" : "Open"}
                  </button>
                  <button
                    onClick={() => void softDelete(r)}
                    className="px-2 py-1 text-sm rounded border text-red-600"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            ))}
            {!filtered.length && (
              <tr>
                <td className="px-3 py-6 text-center text-gray-500" colSpan={10}>
                  No merchants match the filters.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
