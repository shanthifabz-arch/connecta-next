// src/utils/formatConnectaBadge.ts

export type BadgeInput = {
  // REQUIRED country code (always present by spec)
  cc: string;                               // e.g., "IN", "BD", "US"

  // State name or code; omit only if "ALL" selected
  state?: string | null;                    // e.g., "Tamil Nadu" or "TN"

  // Parent identity (preferred if present)
  parent_level?: string | null;             // e.g., "AD"
  parent_level_sequence?: number | string | null; // e.g., 38003

  // Child identity (preferred if present)
  level?: string | null;                    // e.g., "AE"
  serial?: number | string | null;          // e.g., 2001

  // Or parse from connectaID like "AD2-AE-2001"
  connectaID?: string | null;

  // Name for tail label (company short name preferred, else full name)
  companyShortName?: string | null;
  fullName?: string | null;
};

export type BadgeOptions = {
  brand?: string;     // default "CONNECTA"
  nameLen?: number;   // default 10
  sep?: string;       // default " "
};

// --- Helpers ---
const ST_MAP_IN: Record<string, string> = {
  "tamil nadu": "TN", "karnataka": "KA", "kerala": "KL", "andhra pradesh": "AP",
  "telangana": "TS", "maharashtra": "MH", "gujarat": "GJ", "west bengal": "WB",
  "uttar pradesh": "UP", "madhya pradesh": "MP", "rajasthan": "RJ", "punjab": "PB",
  "haryana": "HR", "delhi": "DL", "chhattisgarh": "CT", "odisha": "OD",
  "uttarakhand": "UT", "himachal pradesh": "HP", "bihar": "BR", "jharkhand": "JH",
  "goa": "GA", "assam": "AS", "tripura": "TR", "manipur": "MN", "meghalaya": "ML",
  "mizoram": "MZ", "nagaland": "NL", "sikkim": "SK", "jammu and kashmir": "JK",
  "ladakh": "LA",
};

const norm = (s?: string | null) => (s ?? "").trim().toLowerCase();
const onlyAZ = (s: string) => s.replace(/[^A-Za-z]/g, "");

/** True when state means "ALL STATES SELECTED" */
function isAllStates(s?: string | null) {
  const v = norm(s);
  return v === "all" || v === "all states" || v === "*" || v === "any";
}

/** Derive a 2-letter state code; prefer India map, else initials. */
function deriveStateCode(cc: string, state?: string | null): string {
  if (!state || isAllStates(state)) return "";
  const ccU = (cc || "").toUpperCase();
  const key = norm(state);
  if (ccU === "IN" && ST_MAP_IN[key]) return ST_MAP_IN[key];
  // Fallback: initials from words, else first 2 letters
  const label = (state ?? "").trim();
  const initials = label
    .split(/\s+/)
    .map(w => (w[0] || "").toUpperCase())
    .join("")
    .replace(/[^A-Z]/g, "");
  if (initials.length >= 2) return initials.slice(0, 2);
  return onlyAZ(label).toUpperCase().slice(0, 2);
}

/** Keep digits, strip leading zeros (but keep single "0"). */
function digitsPlain(x: number | string | null | undefined): string | null {
  if (x === null || x === undefined) return null;
  let s = String(x).replace(/\D/g, "");
  if (s === "") return null;
  s = s.replace(/^0+(?=\d)/, ""); // "0015" -> "15"
  return s;
}

/** Parse "AD2-AE-2001" → { parentLevel:"AD", parentOrdinal:"2", level:"AE", serial:"2001" } */
function parseConnectaID(cid?: string | null) {
  if (!cid) return {};
  const m = String(cid).trim().toUpperCase().match(/^([A-Z]{2,3})(\d+)-([A-Z]{2,3})-([0-9]+)$/);
  if (!m) return {};
  const [, pLevel, pOrd, cLevel, cSerial] = m;
  return {
    parentLevel: pLevel,
    parentOrdinal: digitsPlain(pOrd) ?? undefined,
    level: cLevel,
    serial: digitsPlain(cSerial) ?? undefined,
  };
}

function sanitizeShortName(s?: string | null, maxLen = 10) {
  const base = (s ?? "").trim();
  if (!base) return "";
  const cleaned = base
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "") // remove diacritics
    // strip obvious emoji/pictographs without relying on heavy unicode classes
    .replace(/[\u{1F300}-\u{1FAFF}\u{1F600}-\u{1F64F}]/gu, "")
    .replace(/[^\w .&-]/g, "")
    .replace(/\s+/g, " ")
    .trim();
  return cleaned.slice(0, maxLen);
}

/**
 * Final string: "IN TN AD38003 AE 2001 CONNECTA(ShortName)"
 * - CC always present (required input.cc).
 * - State omitted ONLY when "ALL" selected.
 * - No zero-padding anywhere.
 * - ParentID prefers (parent_level + parent_level_sequence); else falls back to AD2 from connectaID.
 */
export function formatConnectaBadge(input: BadgeInput, opts: BadgeOptions = {}): string {
  const {
    cc, state, parent_level, parent_level_sequence, level, serial, connectaID,
    companyShortName, fullName
  } = input;

  const { brand = "CONNECTA", nameLen = 10, sep = " " } = opts;

  // CC (required)
  const CC = (cc || "").toUpperCase();

  // ST (omit only if ALL)
  const ST = isAllStates(state) ? "" : deriveStateCode(CC, state);

  // Prefer explicit fields; else parse connectaID
  const parsed = parseConnectaID(connectaID);

  // ParentID: prefer level + level-sequence; else AD2 from connectaID; else maybe just level.
  const pLevel = (parent_level ?? parsed.parentLevel ?? "")
    .toString()
    .toUpperCase()
    .replace(/[^A-Z]/g, "");
  const pSeq   = digitsPlain(parent_level_sequence ?? parsed.parentOrdinal ?? null);
  const parentID = pLevel
    ? (pSeq ? `${pLevel}${pSeq}` : pLevel)
    : (parsed.parentOrdinal ? `${parsed.parentLevel}${parsed.parentOrdinal}` : "");

  // Child
  const cLevel  = (level ?? parsed.level ?? "")
    .toString()
    .toUpperCase()
    .replace(/[^A-Z]/g, "");
  const cSerial = digitsPlain(serial ?? parsed.serial ?? null);

  // Short name (max 10); prefer company short name
  const sName = sanitizeShortName(companyShortName || fullName, nameLen);

  const out: string[] = [CC];
  if (ST) out.push(ST);
  if (parentID) out.push(parentID);
  if (cLevel) out.push(cLevel);
  if (cSerial) out.push(cSerial);
  out.push(sName ? `${brand}(${sName})` : brand);

  return out.join(sep).trim();
}
