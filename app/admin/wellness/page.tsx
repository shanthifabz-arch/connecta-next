"use client";

import React, { useEffect, useMemo, useState } from "react";

/* ========= Types ========= */

type Program = {
  id: string;
  name: string;
  country_code: string;
  timezone: string;
  default_language_code: string;
  start_time_local: string;
  days_of_week: number[];
  is_active: boolean;
  created_at: string;
  updated_at: string;
};

type WindowRow = {
  id?: string;
  program_id: string;
  window_index: number; // 1..3
  offset_sec: number;
  reveal_seconds: number;
  window_marks: number;
  announce: boolean;
  created_at?: string;
  updated_at?: string;
};

type AudioRow = {
  id?: string;
  program_id: string;
  language_code: string;
  audio_url: string;
  enabled: boolean;
  volume: number | null;
  created_at?: string;
  updated_at?: string;
};

type MasterItem = {
  id: string;
  code: string;
  name: string;
  category?: string | null;
  default_duration_min?: number | null;
  default_marks?: number | null;
  require_code_default?: boolean | null;
};

type ProgramItem = {
  position_index: number;      // 1..50
  master_code: string;         // references MasterItem.code
  marks?: number | null;
  require_code?: boolean;
  visible?: boolean;
  duration_min?: number | null;
  start_offset_sec?: number | null;
};

/* ========= Page ========= */

export default function WellnessAdminPage() {
  const [loading, setLoading] = useState(true);
  const [programs, setPrograms] = useState<Program[]>([]);
  const [selectedProgramId, setSelectedProgramId] = useState<string>("");

  const [windows, setWindows] = useState<WindowRow[]>([]);
  const [audios, setAudios] = useState<AudioRow[]>([]);
  const [savingWin, setSavingWin] = useState(false);
  const [savingAud, setSavingAud] = useState(false);

  // Items state
  const [masterItems, setMasterItems] = useState<MasterItem[]>([]);
  const [progItems, setProgItems] = useState<ProgramItem[]>(
    Array.from({ length: 50 }, (_, i) => ({
      position_index: i + 1,
      master_code: "",
      marks: null,
      require_code: false,
      visible: true,
      duration_min: null,
      start_offset_sec: null,
    }))
  );
  const [savingItems, setSavingItems] = useState(false);

  // Preview JSON
  const [preview, setPreview] = useState<string>("");

  const [msg, setMsg] = useState<string>("");

  const selectedProgram = useMemo(
    () => programs.find((p) => p.id === selectedProgramId) || null,
    [programs, selectedProgramId]
  );

  /* ===== Initial load: programs ===== */
  useEffect(() => {
    (async () => {
      setLoading(true);
      setMsg("");
      try {
        const res = await fetch("/api/admin/wellness/programs", { cache: "no-store" });
        const js = await res.json();
        if (!js.ok) throw new Error(js.error || "Programs fetch failed");
        setPrograms(js.programs || []);
        if (!selectedProgramId && js.programs?.length) {
          setSelectedProgramId(js.programs[0].id);
        }
      } catch (e: any) {
        setMsg(`Load error: ${e.message || e}`);
      } finally {
        setLoading(false);
      }
    })();
  }, []); // once

  /* ===== Load per-program stuff when selection changes ===== */
  useEffect(() => {
    (async () => {
      if (!selectedProgramId) return;
      setMsg("");
      setPreview(""); // clear preview when switching
      try {
        const [wRes, aRes, mRes, piRes] = await Promise.all([
          fetch(`/api/admin/wellness/programs/${selectedProgramId}/windows`, { cache: "no-store" }),
          fetch(`/api/admin/wellness/programs/${selectedProgramId}/audios`, { cache: "no-store" }),
          fetch("/api/admin/wellness/master-items", { cache: "no-store" }),
          fetch(`/api/admin/wellness/programs/${selectedProgramId}/items`, { cache: "no-store" }),
        ]);

        const [wJs, aJs, mJs, piJs] = await Promise.all([wRes.json(), aRes.json(), mRes.json(), piRes.json()]);

        if (!wJs.ok) throw new Error(wJs.error || "Windows fetch failed");
        if (!aJs.ok) throw new Error(aJs.error || "Audios fetch failed");
        if (!mJs.ok) throw new Error(mJs.error || "Master items fetch failed");
        if (!piJs.ok) throw new Error(piJs.error || "Program items fetch failed");

        setWindows((wJs.windows || []).sort((a: WindowRow, b: WindowRow) => a.window_index - b.window_index));
        setAudios((aJs.audios || []).sort((a: AudioRow, b: AudioRow) => a.language_code.localeCompare(b.language_code)));
        setMasterItems(mJs.items || []);

        // Fill 50 slots with existing program items mapped by position
        const got: ProgramItem[] = piJs.items || [];
        const byPos = new Map(got.map((r: ProgramItem) => [r.position_index, r]));
        setProgItems(
          Array.from({ length: 50 }, (_, i) => {
            const p = i + 1;
            return (
              byPos.get(p) || {
                position_index: p,
                master_code: "",
                marks: null,
                require_code: false,
                visible: true,
                duration_min: null,
                start_offset_sec: null,
              }
            );
          })
        );
      } catch (e: any) {
        setMsg(`Program data error: ${e.message || e}`);
      }
    })();
  }, [selectedProgramId]);

  /* ===== Windows helpers ===== */
  const ensureWindowDefaults = (n: 1 | 2 | 3): WindowRow => {
    return (
      windows.find((x) => x.window_index === n) || {
        program_id: selectedProgramId,
        window_index: n,
        offset_sec: n === 1 ? 300 : n === 2 ? 900 : 1500,
        reveal_seconds: 60,
        window_marks: 5,
        announce: true,
      }
    );
  };

  const updateWindow = (idx: number, patch: Partial<WindowRow>) => {
    setWindows((ws) => {
      const exists = ws.some((w) => w.window_index === idx);
      if (!exists) {
        return [...ws, { ...ensureWindowDefaults(idx as 1 | 2 | 3), ...patch }];
      }
      return ws.map((w) => (w.window_index === idx ? { ...w, ...patch } : w));
    });
  };

  const saveWindows = async () => {
    if (!selectedProgramId) return;
    setSavingWin(true);
    setMsg("");
    try {
      const merged = [1, 2, 3].map((n) => ensureWindowDefaults(n as 1 | 2 | 3)).map((w) => ({
        window_index: Number(w.window_index),
        offset_sec: Number(w.offset_sec),
        reveal_seconds: Number(w.reveal_seconds || 60),
        window_marks: Number(w.window_marks || 5),
        announce: !!w.announce,
      }));

      const res = await fetch(`/api/admin/wellness/programs/${selectedProgramId}/windows`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(merged),
      });
      const js = await res.json();
      if (!js.ok) throw new Error(js.error || "Save windows failed");
      setWindows(js.windows || []);
      setMsg("Windows saved ✅");
    } catch (e: any) {
      setMsg(`Save windows error: ${e.message || e}`);
    } finally {
      setSavingWin(false);
    }
  };

  /* ===== Audio helpers ===== */
  const addAudioRow = () => {
    if (!selectedProgramId) return;
    setAudios((a) => [
      ...a,
      {
        program_id: selectedProgramId,
        language_code: "",
        audio_url: "",
        enabled: false,
        volume: 0.9,
      },
    ]);
  };

  const updateAudio = (i: number, patch: Partial<AudioRow>) => {
    setAudios((a) => a.map((row, idx) => (idx === i ? { ...row, ...patch } : row)));
  };

  const removeAudio = (i: number) => {
    setAudios((a) => a.filter((_, idx) => idx !== i));
  };

  const saveAudios = async () => {
    if (!selectedProgramId) return;
    setSavingAud(true);
    setMsg("");
    try {
      const cleaned = audios
        .map((a) => ({
          language_code: String(a.language_code || "").trim(),
          audio_url: String(a.audio_url || "").trim(),
          enabled: !!a.enabled,
          volume: typeof a.volume === "number" ? Math.max(0, Math.min(1, a.volume)) : null,
        }))
        .filter((a) => a.language_code && a.audio_url);

      const res = await fetch(`/api/admin/wellness/programs/${selectedProgramId}/audios`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(cleaned),
      });
      const js = await res.json();
      if (!js.ok) throw new Error(js.error || "Save audios failed");
      setAudios(js.audios || []);
      setMsg("Audios saved ✅");
    } catch (e: any) {
      setMsg(`Save audios error: ${e.message || e}`);
    } finally {
      setSavingAud(false);
    }
  };

  /* ===== Items helpers ===== */
  const updateProgItem = (pos: number, patch: Partial<ProgramItem>) => {
    setProgItems((rows) =>
      rows.map((r) => (r.position_index === pos ? { ...r, ...patch } : r))
    );
  };

  const saveItems = async () => {
    if (!selectedProgramId) return;
    setSavingItems(true);
    setMsg("");
    try {
      const payload = progItems
        .filter((r) => r.master_code) // only filled rows
        .map((r) => ({
          position_index: r.position_index,
          master_code: r.master_code,
          marks: r.marks === null || r.marks === undefined || Number.isNaN(Number(r.marks)) ? null : Number(r.marks),
          require_code: !!r.require_code,
          visible: r.visible !== false,
          duration_min:
            r.duration_min === null || r.duration_min === undefined || Number.isNaN(Number(r.duration_min))
              ? null
              : Number(r.duration_min),
          start_offset_sec:
            r.start_offset_sec === null || r.start_offset_sec === undefined || Number.isNaN(Number(r.start_offset_sec))
              ? null
              : Number(r.start_offset_sec),
        }));

      const res = await fetch(`/api/admin/wellness/programs/${selectedProgramId}/items`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      const js = await res.json();
      if (!js.ok) throw new Error(js.error || "Save items failed");
      setMsg("Items saved ✅");
    } catch (e: any) {
      setMsg(`Save items error: ${e.message || e}`);
    } finally {
      setSavingItems(false);
    }
  };

  /* ===== Preview (no alert; pretty + copy) ===== */
  const showTodayJson = async () => {
    try {
      if (!selectedProgram) return;
      const tz = selectedProgram.timezone || "Asia/Kolkata";
      const lang = selectedProgram.default_language_code || "en-IN";
      const res = await fetch(
        `/api/wellness/today?timezone=${encodeURIComponent(tz)}&language=${encodeURIComponent(lang)}`
      );
      const js = await res.json();
      setPreview(JSON.stringify(js, null, 2));
    } catch (e: any) {
      setPreview(JSON.stringify({ ok: false, error: e?.message || String(e) }, null, 2));
    }
  };

  return (
    <div className="p-6 max-w-6xl mx-auto">
      <h1 className="text-2xl font-semibold mb-4">Wellness Management (Standalone)</h1>

      {msg && (
        <div className="mb-4 p-3 rounded border border-yellow-300 bg-yellow-50 text-yellow-800">
          {msg}
        </div>
      )}

      {loading ? (
        <div>Loading…</div>
      ) : (
        <>
          {/* Program selector */}
          <div className="mb-6">
            <label className="block text-sm font-medium mb-1">Program</label>
            <select
              className="border rounded px-3 py-2 w-full max-w-md"
              value={selectedProgramId}
              onChange={(e) => setSelectedProgramId(e.target.value)}
            >
              {programs.map((p) => (
                <option key={p.id} value={p.id}>
                  {p.name} — {p.timezone} — {p.default_language_code}
                </option>
              ))}
            </select>
            {selectedProgram && (
              <p className="text-xs text-gray-500 mt-1">
                Start time: {selectedProgram.start_time_local} • Active: {String(selectedProgram.is_active)}
              </p>
            )}
          </div>

          {/* Windows editor */}
          <div className="mb-10">
            <h2 className="text-lg font-medium mb-3">Windows (3 code windows)</h2>
            {[1, 2, 3].map((n) => {
              const w = ensureWindowDefaults(n as 1 | 2 | 3);
              return (
                <div key={n} className="grid grid-cols-5 gap-3 items-center mb-2">
                  <div className="text-sm">Window {n}</div>
                  <input
                    type="number"
                    className="border rounded px-2 py-1"
                    value={w.offset_sec}
                    onChange={(e) => updateWindow(n, { offset_sec: Number(e.target.value) })}
                    placeholder="offset_sec (e.g., 300)"
                  />
                  <input
                    type="number"
                    className="border rounded px-2 py-1"
                    value={w.reveal_seconds}
                    onChange={(e) => updateWindow(n, { reveal_seconds: Number(e.target.value) })}
                    placeholder="reveal_seconds"
                  />
                  <input
                    type="number"
                    className="border rounded px-2 py-1"
                    value={w.window_marks}
                    onChange={(e) => updateWindow(n, { window_marks: Number(e.target.value) })}
                    placeholder="window_marks"
                  />
                  <label className="inline-flex items-center gap-2">
                    <input
                      type="checkbox"
                      checked={!!w.announce}
                      onChange={(e) => updateWindow(n, { announce: e.target.checked })}
                    />
                    <span className="text-sm">Announce</span>
                  </label>
                </div>
              );
            })}
            <button
              onClick={saveWindows}
              disabled={savingWin || !selectedProgramId}
              className="mt-3 rounded px-4 py-2 bg-blue-600 text-white disabled:opacity-60"
            >
              {savingWin ? "Saving…" : "Save Windows"}
            </button>
          </div>

          {/* Audio editor */}
          <div className="mb-10">
            <h2 className="text-lg font-medium mb-3">Language Audio</h2>
            <div className="space-y-2">
              {audios.map((row, idx) => (
                <div key={idx} className="grid grid-cols-6 gap-3 items-center">
                  <input
                    className="border rounded px-2 py-1"
                    placeholder="language_code (e.g., ta-IN)"
                    value={row.language_code}
                    onChange={(e) => updateAudio(idx, { language_code: e.target.value })}
                  />
                  <input
                    className="border rounded px-2 py-1 col-span-2"
                    placeholder="audio_url"
                    value={row.audio_url}
                    onChange={(e) => updateAudio(idx, { audio_url: e.target.value })}
                  />
                  <label className="inline-flex items-center gap-2">
                    <input
                      type="checkbox"
                      checked={!!row.enabled}
                      onChange={(e) => updateAudio(idx, { enabled: e.target.checked })}
                    />
                    <span className="text-sm">Enabled</span>
                  </label>
                  <input
                    type="number"
                    step="0.05"
                    min={0}
                    max={1}
                    className="border rounded px-2 py-1"
                    placeholder="volume 0..1"
                    value={row.volume ?? 0.9}
                    onChange={(e) => updateAudio(idx, { volume: Number(e.target.value) })}
                  />
                  <button onClick={() => removeAudio(idx)} className="rounded px-3 py-1 bg-red-100 text-red-700">
                    Remove
                  </button>
                </div>
              ))}
            </div>
            <div className="mt-3 flex gap-3">
              <button onClick={addAudioRow} className="rounded px-4 py-2 bg-gray-200">
                + Add Language
              </button>
              <button
                onClick={saveAudios}
                disabled={savingAud || !selectedProgramId}
                className="rounded px-4 py-2 bg-blue-600 text-white disabled:opacity-60"
              >
                {savingAud ? "Saving…" : "Save Audios"}
              </button>
            </div>
          </div>

          {/* Items editor (up to 50) */}
          <div className="mb-10">
            <h2 className="text-lg font-medium mb-3">Items (up to 50)</h2>

            <div className="grid grid-cols-8 gap-2 font-semibold text-sm mb-2">
              <div>#</div>
              <div className="col-span-3">Master Item</div>
              <div>Marks</div>
              <div>Require Code</div>
              <div>Visible</div>
              <div className="text-right">Offset (sec)</div>
            </div>

            {progItems.map((row) => (
              <div key={row.position_index} className="grid grid-cols-8 gap-2 items-center mb-1">
                <div className="text-xs text-gray-600">#{row.position_index}</div>

                {/* Master select */}
                <select
                  className="col-span-3 border rounded px-2 py-1"
                  value={row.master_code}
                  onChange={(e) => updateProgItem(row.position_index, { master_code: e.target.value })}
                >
                  <option value="">-- select item --</option>
                  {masterItems.map((mi) => (
                    <option key={mi.code} value={mi.code}>
                      {mi.name} ({mi.code})
                    </option>
                  ))}
                </select>

                {/* Marks */}
                <input
                  type="number"
                  className="border rounded px-2 py-1"
                  value={row.marks ?? ""}
                  onChange={(e) =>
                    updateProgItem(row.position_index, {
                      marks: e.target.value === "" ? null : Number(e.target.value),
                    })
                  }
                  placeholder="marks"
                />

                {/* Require code */}
                <label className="inline-flex items-center justify-center gap-2">
                  <input
                    type="checkbox"
                    checked={!!row.require_code}
                    onChange={(e) => updateProgItem(row.position_index, { require_code: e.target.checked })}
                  />
                </label>

                {/* Visible */}
                <label className="inline-flex items-center justify-center gap-2">
                  <input
                    type="checkbox"
                    checked={row.visible !== false}
                    onChange={(e) => updateProgItem(row.position_index, { visible: e.target.checked })}
                  />
                </label>

                {/* Optional: per-item start offset */}
                <input
                  type="number"
                  className="border rounded px-2 py-1 text-right"
                  value={row.start_offset_sec ?? ""}
                  onChange={(e) =>
                    updateProgItem(row.position_index, {
                      start_offset_sec: e.target.value === "" ? null : Number(e.target.value),
                    })
                  }
                  placeholder="e.g. 600"
                />
              </div>
            ))}

            <div className="mt-3">
              <button
                onClick={saveItems}
                disabled={savingItems || !selectedProgramId}
                className="rounded px-4 py-2 bg-blue-600 text-white disabled:opacity-60"
              >
                {savingItems ? "Saving…" : "Save Items"}
              </button>
            </div>
          </div>

          {/* Live “Today” preview (inline pretty JSON) */}
          <div className="mb-12">
            <h2 className="text-lg font-medium mb-3">Preview: Today JSON</h2>
            <div className="flex gap-3 mb-3">
              <button className="rounded px-4 py-2 bg-gray-200" onClick={showTodayJson}>
                Show Today JSON
              </button>
              <button
                disabled={!preview}
                className="rounded px-4 py-2 bg-gray-200 disabled:opacity-60"
                onClick={() => preview && navigator.clipboard.writeText(preview)}
              >
                Copy
              </button>
            </div>
            {preview && (
              <pre className="whitespace-pre-wrap bg-black text-green-400 p-3 rounded max-h-[500px] overflow-auto text-sm">
                {preview}
              </pre>
            )}
          </div>
        </>
      )}
    </div>
  );
}
