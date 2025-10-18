"use client";

export default function PostJoinBadge({
  country,
  state,
}: {
  country?: string;
  state?: string;
}) {
  if (!country && !state) return null;
  return (
    <span className="px-2 py-0.5 text-xs rounded-md bg-blue-100 text-blue-800 border border-blue-200">
      {(country || "—") + (state ? ` • ${state}` : "")}
    </span>
  );
}
