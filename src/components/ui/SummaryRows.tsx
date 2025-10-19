// src/components/ui/SummaryRows.tsx
type PhoneProps = { primary?: string; recovery?: string; className?: string };
export function PhoneSummary({ primary, recovery, className = "" }: PhoneProps) {
  return (
    <div className={`rounded-md border px-3 py-2 leading-tight mb-4 ${className}`}>
      <div className="flex items-center justify-between text-xs">
        <span className="font-semibold uppercase tracking-wide">PRIMARY PHONE</span>
        <span className="font-mono font-bold truncate">{primary || "—"}</span>
      </div>
      <div className="flex items-center justify-between text-xs">
        <span className="font-semibold uppercase tracking-wide">RECOVERY PHONE</span>
        <span className="font-mono font-bold truncate">{recovery || "—"}</span>
      </div>
    </div>
  );
}

type RegionProps = { language?: string; country?: string; state?: string; className?: string };
export function RegionLangSummary({ language, country, state, className = "" }: RegionProps) {
  return (
    <div className={`rounded-md border px-3 py-2 leading-tight mb-4 ${className}`}>
      <div className="flex items-center justify-between text-xs">
        <span className="font-semibold uppercase tracking-wide">LANGUAGE</span>
        <span className="font-mono font-bold truncate">{language || "—"}</span>
      </div>
      <div className="flex items-center justify-between text-xs">
        <span className="font-semibold uppercase tracking-wide">COUNTRY</span>
        <span className="font-mono font-bold truncate">{country || "—"}</span>
      </div>
      <div className="flex items-center justify-between text-xs">
        <span className="font-semibold uppercase tracking-wide">STATE</span>
        <span className="font-mono font-bold truncate">{state || "—"}</span>
      </div>
    </div>
  );
}
