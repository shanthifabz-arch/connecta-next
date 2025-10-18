"use client";

import { useSearchParams } from "next/navigation";
import Link from "next/link";
import { useMemo, useCallback } from "react";

export default function PostJoin() {
  const sp = useSearchParams();

  const ref = sp.get("ref") ?? "";
  const country = sp.get("country") ?? "";
  const state = sp.get("state") ?? "";
  const mobile = sp.get("mobile") ?? "";
  const recovery = sp.get("recovery") ?? sp.get("recoveryMobile") ?? "";
  const prefix = sp.get("prefix") ?? "";

  const inviteLink = useMemo(() => {
    const origin = typeof window !== "undefined" ? window.location.origin : "";
    const qp = new URLSearchParams({ ref });
    return `${origin}/welcome?${qp.toString()}`;
  }, [ref]);

  const copy = useCallback(async (text: string, label: string) => {
    try {
      await navigator.clipboard.writeText(text);
      alert(`${label} copied`);
    } catch {
      alert(`Could not copy ${label.toLowerCase()}`);
    }
  }, []);

  function waShare() {
    const msg = `Here is my Connecta referral code: ${ref}\nLink: ${inviteLink}`;
    const url = "https://wa.me?text=" + encodeURIComponent(msg);
    if (typeof window !== "undefined") window.open(url, "_blank");
  }

  if (!ref) {
    return (
      <div className="min-h-screen grid place-items-center p-6">
        <div className="max-w-lg w-full">
          <h1 className="text-2xl font-bold mb-2">Missing referral code</h1>
          <p className="text-sm text-gray-600 mb-4">
            This page expects a <code className="font-mono">ref</code> query param. Go back to the onboarding form.
          </p>
          <Link href="/onboarding-tabs" className="text-blue-600 underline">
            Back to onboarding
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-white text-black px-4 py-6">
      <div className="max-w-2xl mx-auto">
        <h1 className="text-2xl font-bold text-blue-700">You're in 🎉</h1>
        <p className="text-sm text-gray-700 mb-4">Share your referral or continue adding connectors.</p>

        {/* Recap */}
        <div className="rounded-md border border-blue-200 bg-blue-50 text-blue-900 px-3 py-2 leading-tight mb-4">
          <div className="flex items-center justify-between text-xs">
            <span className="font-semibold uppercase tracking-wide">Referral code</span>
            <span className="font-mono font-bold truncate">{ref}</span>
          </div>
          <div className="flex items-center justify-between text-xs">
            <span className="font-semibold uppercase tracking-wide">Primary phone</span>
            <span className="font-mono font-bold truncate">{mobile || "—"}</span>
          </div>
          <div className="flex items-center justify-between text-xs">
            <span className="font-semibold uppercase tracking-wide">Recovery phone</span>
            <span className="font-mono font-bold truncate">{recovery || "—"}</span>
          </div>
          <div className="flex items-center justify-between text-xs">
            <span className="font-semibold uppercase tracking-wide">Region</span>
            <span className="font-mono font-bold truncate">
              {country || "—"} {state ? `• ${state}` : ""}
            </span>
          </div>
        </div>

        {/* Actions */}
        <div className="grid gap-2 mb-6">
          <button onClick={() => copy(ref, "Referral code")} className="px-4 py-2 rounded-md bg-blue-100">
            Copy referral code
          </button>
          <button onClick={() => copy(inviteLink, "Invite link")} className="px-4 py-2 rounded-md bg-gray-100">
            Copy invite link
          </button>
          <button onClick={waShare} className="px-4 py-2 rounded-md bg-green-200">
            Share on WhatsApp
          </button>
        </div>

        {/* Next steps */}
        <div className="grid gap-2">
          <Link
            href={`/onboarding-tabs?ref=${encodeURIComponent(ref)}&country=${encodeURIComponent(
              country
            )}&state=${encodeURIComponent(state)}&mobile=${encodeURIComponent(
              mobile
            )}&recoveryMobile=${encodeURIComponent(recovery)}&prefix=${encodeURIComponent(prefix)}`}
            className="inline-block px-4 py-2 rounded bg-blue-600 text-white hover:bg-blue-700"
          >
            Add more connectors
          </Link>

          <div className="flex gap-2">
            <Link
              href={`/b2c?ref=${encodeURIComponent(ref)}&country=${encodeURIComponent(
                country
              )}&state=${encodeURIComponent(state)}&mobile=${encodeURIComponent(
                mobile
              )}&recoveryMobile=${encodeURIComponent(recovery)}&prefix=${encodeURIComponent(prefix)}`}
              className="px-4 py-2 rounded border"
            >
              Open B2C form
            </Link>
            <Link
              href={`/b2b?ref=${encodeURIComponent(ref)}&country=${encodeURIComponent(
                country
              )}&state=${encodeURIComponent(state)}&mobile=${encodeURIComponent(
                mobile
              )}&recoveryMobile=${encodeURIComponent(recovery)}&prefix=${encodeURIComponent(prefix)}`}
              className="px-4 py-2 rounded border"
            >
              Open B2B form
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
