"use client";

import { useState, useEffect } from "react";
import { supabase } from "@/lib/supabaseClient";

interface Connector {
  id: string;
  mobile: string;
  COUNTRY: string;
  STATE: string;
  LANGUAGE: string;
  created_at: string;
}

const PAGE_SIZE = 10;

export default function ReadOnlyViewer() {
  const [connectors, setConnectors] = useState<Connector[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [filtered, setFiltered] = useState<Connector[]>([]);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(false);
  const [totalCount, setTotalCount] = useState(0);

  // Fetch connectors with pagination and total count
  const fetchConnectors = async (pageNumber: number, search = "") => {
    setLoading(true);
    const from = (pageNumber - 1) * PAGE_SIZE;
    const to = from + PAGE_SIZE - 1;

    // Filtering with search on mobile number (case insensitive)
    const query = supabase
      .from("aa_connectors")
      .select("*", { count: "exact" })
      .order("created_at", { ascending: false })
      .range(from, to);

    if (search.trim()) {
      query.ilike("mobile", `%${search}%`);
    }

    const { data, count, error } = await query;

    if (error) {
      alert("Error fetching data");
      console.error(error);
      setLoading(false);
      return;
    }

    setConnectors(data || []);
    setTotalCount(count || 0);
    setLoading(false);
  };

  // Initial fetch and on page/search change
  useEffect(() => {
    fetchConnectors(page, searchTerm);
  }, [page, searchTerm]);

  // Handle search input
  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setPage(1);
    setSearchTerm(e.target.value);
  };

  // Pagination buttons count
  const totalPages = Math.ceil(totalCount / PAGE_SIZE);

  return (
    <div className="p-6 max-w-5xl mx-auto">
      <h2 className="text-2xl font-bold mb-4 text-blue-700">Read-Only Viewer</h2>

      <input
        type="text"
        placeholder="Search mobile number..."
        value={searchTerm}
        onChange={handleSearchChange}
        className="border p-2 rounded w-64 mb-4"
      />

      {loading ? (
        <p>Loading...</p>
      ) : connectors.length === 0 ? (
        <p>No records found.</p>
      ) : (
        <>
          <table className="min-w-full border border-gray-300 rounded-lg text-center">
            <thead className="bg-gray-100">
              <tr>
                <th className="p-2 border">#</th>
                <th className="p-2 border">Mobile</th>
                <th className="p-2 border">Country</th>
                <th className="p-2 border">State</th>
                <th className="p-2 border">Language</th>
                <th className="p-2 border">Created At</th>
              </tr>
            </thead>
            <tbody>
              {connectors.map((c, idx) => (
                <tr key={c.id} className="border-t">
                  <td className="p-2 border">{(page - 1) * PAGE_SIZE + idx + 1}</td>
                  <td className="p-2 border">{c.mobile}</td>
                  <td className="p-2 border">{c.COUNTRY}</td>
                  <td className="p-2 border">{c.STATE}</td>
                  <td className="p-2 border">{c.LANGUAGE}</td>
                  <td className="p-2 border">
                    {new Date(c.created_at).toLocaleString()}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          {/* Pagination */}
          <div className="flex justify-center gap-2 mt-4">
            <button
              disabled={page <= 1}
              onClick={() => setPage(page - 1)}
              className="px-3 py-1 border rounded disabled:opacity-50"
            >
              Prev
            </button>

            <span className="px-3 py-1 border rounded bg-gray-200">
              Page {page} of {totalPages}
            </span>

            <button
              disabled={page >= totalPages}
              onClick={() => setPage(page + 1)}
              className="px-3 py-1 border rounded disabled:opacity-50"
            >
              Next
            </button>
          </div>
        </>
      )}
    </div>
  );
}

