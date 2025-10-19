"use client";

import React, { useEffect, useMemo, useState } from "react";
import { useSearchParams } from "next/navigation";
import PostJoinBadge from "@/components/ui/PostJoinBadge";
import { createClient } from "@supabase/supabase-js";

/** tiny helper */
function copy(text: string) {
  return navigator.clipboard.writeText(text);
}

export default function PostJoinPage() {
  const sp = useSearchParams();

  // URL params (id is preferred; ref is fallback)
  const id = sp?.get("id") ?? "";
  const ref = sp?.get("ref") ?? "";
  const country = sp?.get("country") ?? "";
  const state = sp?.get("state") ?? "";
  const mobile = sp?.get("mobile") ?? "";
  const recovery = sp?.get("recovery") ?? "";
  const connectaIdFromQS = sp?.get("connectaId") ?? ""; // seed if provided by redirect

  const invitePathRaw =
    sp?.get("invitePath") ?? process.env.NEXT_PUBLIC_INVITE_PATH ?? "/welcome";
  const invitePath =
    invitePathRaw?.startsWith("/") ? invitePathRaw : `/${invitePathRaw}`;

  // Supabase client (browser)
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;
  const sb = useMemo(
    () =>
      supabaseUrl && supabaseKey ? createClient(supabaseUrl, supabaseKey) : null,
    [supabaseUrl, supabaseKey]
  );

  // Canonical value from DB (seed from QS if present)
  const [globalId, setGlobalId] = useState<string>(connectaIdFromQS);
  const [gidLoading, setGidLoading] = useState(false);

  useEffect(() => {
    if (!sb) return;
    let alive = true;

    async function fetchGlobalById(theId: string) {
      const { data, error } = await sb
        .from("connectors")
        .select("global_connecta_id")
        .eq("id", theId)
        .maybeSingle();
      if (error) throw error;
      return data?.global_connecta_id ?? "";
    }

    async function fetchGlobalByRef(theRef: string) {
      // Try createdAt, then created_at
      let q = await sb
        .from("connectors")
        .select("global_connecta_id")
        .eq("referralCode", theRef)
        .order("createdAt", { ascending: false })
        .limit(1)
        .maybeSingle();

      if (!q.data || q.error) {
        q = await sb
          .from("connectors")
          .select("global_connecta_id")
          .eq("referralCode", theRef)
          .order("created_at", { ascending: false })
          .limit(1)
          .maybeSingle();
      }

      if (q.error) throw q.error;
      return q.data?.global_connecta_id ?? "";
    }

    (async () => {
      setGidLoading(true);
      try {
        let gid = globalId; // keep whatever QS gave us until DB confirms
        if (id) gid = await fetchGlobalById(id);
        else if (ref) gid = await fetchGlobalByRef(ref);
        if (alive) setGlobalId(gid);
      } catch (e) {
        console.warn("[post-join] fetch failed:", (e as any)?.message || e);
        if (alive) setGlobalId(globalId || "");
      } finally {
        if (alive) setGidLoading(false);
      }
    })();

    return () => {
      alive = false;
    };
  }, [sb, id, ref]); // keep deps minimal

  // Share helpers
  const origin = typeof window !== "undefined" ? window.location.origin : "";
  const inviteLink = useMemo(() => {
    if (!ref) return "";
    return `${origin}${invitePath}?ref=${encodeURIComponent(ref)}`;
  }, [origin, invitePath, ref]);

  const inviteMessage = useMemo(() => {
    const head = "You are invited to Join CONNECTA Community.";
    const gidLine = `Global CONNECTA ID: ${globalId || (gidLoading ? "loading…" : "—")}`;
    const mid = "Please download our App and join with this referral code:";
    const link = inviteLink || `${origin}${invitePath}`;
    return `${head}\n${gidLine}\n${mid} ${ref || "—"}\nLink: ${link}`;
  }, [globalId, gidLoading, ref, inviteLink, origin, invitePath]);

  return (
    <div className="min-h-screen bg-white text-black px-4 py-6">
      <div className="max-w-3xl mx-auto">
        {/* Title + region pill */}
        <div className="flex items-center gap-3 mb-4">
          <h1 className="text-2xl font-bold text-blue-700">You&apos;re in 🎉</h1>
          <PostJoinBadge country={country} state={state} />
        </div>
        <p className="text-sm text-gray-700 mb-3">
          Share your referral or continue adding connectors.
        </p>

        {/* Recap card */}
        <div className="rounded-md border border-blue-200 bg-blue-50 text-blue-900 px-3 py-2 leading-tight mb-3">
          <div className="grid grid-cols-2 gap-x-4 text-xs">
            <div className="font-semibold uppercase tracking-wide">GLOBAL CONNECTA ID</div>
            <div className="text-right font-mono font-bold truncate">
              {gidLoading ? "loading…" : globalId || "—"}
            </div>

            <div className="font-semibold uppercase tracking-wide">REFERRAL CODE</div>
            <div className="text-right font-mono font-bold truncate">{ref || "—"}</div>

            <div className="font-semibold uppercase tracking-wide">PRIMARY PHONE</div>
            <div className="text-right font-mono font-bold truncate">{mobile || "—"}</div>

            <div className="font-semibold uppercase tracking-wide">RECOVERY PHONE</div>
            <div className="text-right font-mono font-bold truncate">{recovery || "—"}</div>

            <div className="font-semibold uppercase tracking-wide">REGION</div>
            <div className="text-right font-mono font-bold truncate">
              {country || "—"} • {state || "—"}
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="space-y-3 mb-6">
          <button
            disabled={!globalId}
            onClick={() => copy(globalId).then(() => alert("Global CONNECTA ID copied!"))}
            className="w-full rounded-md px-4 py-2 disabled:opacity-60 disabled:cursor-not-allowed"
            style={{ backgroundColor: "#eef2ff" }}
            title={globalId ? "" : "Global ID not available yet"}
          >
            Copy Global CONNECTA ID
          </button>

          <button
            onClick={() => copy(ref).then(() => alert("Referral code copied!"))}
            className="w-full rounded-md bg-blue-100 px-4 py-2"
          >
            Copy referral code
          </button>

          <button
            onClick={() => copy(inviteMessage).then(() => alert("Invite message copied!"))}
            className="w-full rounded-md bg-gray-100 px-4 py-2"
          >
            Copy invite message
          </button>

          <button
            onClick={() =>
              window.open(`https://wa.me?text=${encodeURIComponent(inviteMessage)}`, "_blank")
            }
            className="w-full rounded-md bg-green-200 px-4 py-2"
          >
            Share on WhatsApp
          </button>
        </div>

        <div className="flex items-center gap-3">
          <a className="px-4 py-2 rounded-md bg-blue-600 text-white" href="/b2c">
            Open B2C form
          </a>
          <a className="px-4 py-2 rounded-md bg-blue-600 text-white" href="/b2b">
            Open B2B form
          </a>
        </div>
      </div>
    </div>
  );
}
