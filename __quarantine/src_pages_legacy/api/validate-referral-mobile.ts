// File: src/pages/api/validate-referral-mobile.ts
import type { NextApiRequest, NextApiResponse } from "next";
import { createClient, PostgrestError } from "@supabase/supabase-js";



const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

// --- Type-light alias to avoid deep generic instantiation in this API route only ---
type AACRow = { id: string | number; aa_joining_code: string | null };
// Use `sb` (any-typed) for queries in this file to avoid TS "excessively deep" errors
const sb = supabase as any;


// Your DB column names
const MOBILE_COL: "mobile" | "mobile_number" | "mobile_e164" = "mobile_number";

type Payload = {
  referralCode?: string;
  mobile?: string;
  type?: "aa" | "child";
  country?: string | null;
  state?: string | null;
};

type ApiResponse = {
  valid: boolean;
  error?: string; // legacy
  code?:
    | "MOBILE_EXISTS"
    | "MOBILE_ALREADY_ON_TREE"
    | "MOBILE_BELONGS_TO_OTHER"
    | "COUNTRY_MISMATCH"
    | "STATE_MISMATCH"
    | "SERVER_ERROR"
    | "BAD_REQUEST"
    | "OK"
    | "BAD_REFERRAL";
  message?: string;
  registeredId?: string | number;
  registeredWith?: {
    id: string;
    referralCode?: string | null;
    level?: string | null;
  };
};

// ---------- helpers ----------
function describeErr(err?: PostgrestError | null) {
  if (!err) return "";
  const parts = [err.code, err.message, err.details, err.hint]
    .filter(Boolean)
    .map(String);
  return parts.join(" | ") || JSON.stringify(err);
}

function isUndefinedColumn(err?: PostgrestError | null) {
  return !!err && (err.code === "42703" || /column .* does not exist/i.test(err.message || ""));
}

// Normalize to +E.164 (lightweight)
function toE164(m: string) {
  const trimmed = (m || "").trim();
  if (!trimmed) return trimmed;
  const digits = trimmed.replace(/[^\d]/g, "");
  return `+${digits}`;
}

// ---- tolerant referral matching utilities ----
function normalizeSpaces(s: string) {
  return s.replace(/\s+/g, " ").trim();
}
function toUnderscore(s: string) {
  return normalizeSpaces(s).replace(/\s/g, "_");
}
function stripTrailingGeneration(code: string) {
  // removes a trailing underscore + alnum suffix, e.g. _G or _GEN1
  return code.replace(/_[A-Za-z0-9]+$/, "");
}
function unique<T>(arr: T[]) {
  return Array.from(new Set(arr));
}

// Fix known legacy typos and punctuation before digits
// - BDDH followed by ’ ' ` or a just before digits -> underscore
// - Backslash before digits -> underscore
// - Collapse multiple underscores
function fixKnownTypos(s: string) {
  let x = s;
  x = x.replace(/BDDH[’'`a]+(?=\d)/gi, "BDDH_");
  x = x.replace(/\\(?=\d)/g, "_");
  x = x.replace(/_+/g, "_");
  return x;
}

// generate punctuation variants to handle ’ / ' / `
function quoteVariants(s: string) {
  const apostrophe = s.replace(/[\u2018\u2019\u201B]/g, "'");
  const backtick = s.replace(/[\u2018\u2019\u201B']/g, "`");
  const stripped = s.replace(/[\u2018\u2019\u201B'`]/g, "");
  return [s, apostrophe, backtick, stripped];
}

// tolerant variant builder
function buildReferralVariants(raw: string) {
  const baseInputs = unique([raw.trim(), fixKnownTypos(raw.trim())]);

  // spaces vs underscores for each input
  const shaped = baseInputs.flatMap((o) => [o, normalizeSpaces(o), toUnderscore(o)]);
  // punctuation variants
  const withQuotes = shaped.flatMap(quoteVariants);
  // also try without generation suffix
  const plusNoGen = withQuotes.flatMap((v) => [v, stripTrailingGeneration(v)]);

  return unique(plusNoGen).filter(Boolean);
}

// compare ignoring case/space/underscore/hyphen
function same(a?: string | null, b?: string | null) {
  const norm = (s?: string | null) => (s || "").toLowerCase().replace(/[\s_-]+/g, "");
  return norm(a) === norm(b);
}

// parse country/state from referral (after typo fixes)
function parseCSFromReferral(code: string) {
  const fixed = fixKnownTypos(code);
  const [refCountry, refState] = fixed.split("_").slice(0, 2).map((s) => (s || "").trim());
  return { refCountry, refState };
}

// --- Robust parent referral finder across both tables with tolerant matching ---
async function findParentByReferral(referralCode: string) {
  type Parent =
    | {
        id: string;
        referralCode?: string | null; // normalized output key
        source: "connectors" | "aa_connectors";
        matched_col: string;
        matched_value: string;
      }
    | null;

  const candidates = buildReferralVariants(referralCode);

  // 1) connectors.referralCode
  for (const cand of candidates) {
    // exact
    const { data, error }: { data: { id: string | number; referralCode?: string | null } | null; error: any } = await sb
  .from("connectors")
  .select("id, referralCode")
  .eq("referralCode", cand)
  .limit(1)
  .maybeSingle();


    if (error && !isUndefinedColumn(error)) {
      return { data: null as Parent, error, tried: `connectors.referralCode` };
    }
    if (data) {
      return {
        data: {
          id: data.id,
          referralCode: (data as any).referralCode,
          source: "connectors",
          matched_col: "referralCode",
          matched_value: cand,
        },
        error: null,
        tried: `connectors.referralCode`,
      };
    }

    // case-insensitive exact
  const ilike: { data: { id: string | number; referralCode?: string | null } | null; error: any } = await sb
  .from("connectors")
  .select("id, referralCode")
  .ilike("referralCode", cand)
  .limit(1)
  .maybeSingle();


    if (!ilike.error && ilike.data) {
      return {
        data: {
          id: ilike.data.id,
          referralCode: (ilike.data as any).referralCode,
          source: "connectors",
          matched_col: "referralCode (ilike)",
          matched_value: cand,
        },
        error: null,
        tried: `connectors.referralCode (ilike)`,
      };
    } else if (ilike.error && !isUndefinedColumn(ilike.error)) {
      return { data: null as Parent, error: ilike.error, tried: `connectors.referralCode (ilike)` };
    }
  }

  // 2) aa_connectors.(aa_joining_code | connector_code)
  const aaCols = ["aa_joining_code", "connector_code"] as const;
  for (const cand of candidates) {
    for (const col of aaCols) {
      // exact
    const { data, error }: { data: AACRow | null; error: any } = await sb
  .from("aa_connectors")
  .select("id, aa_joining_code")
  .eq(col as any, cand)
  .limit(1)
  .maybeSingle();


      if (error) {
        if (!isUndefinedColumn(error)) {
          return { data: null as Parent, error, tried: `aa_connectors.${col}` };
        }
      } else if (data) {
        return {
          data: {
            id: data.id,
            referralCode: (data as any).aa_joining_code,
            source: "aa_connectors",
            matched_col: col,
            matched_value: cand,
          },
          error: null,
          tried: `aa_connectors.${col}`,
        };
      }

      // case-insensitive exact
     const ilike: { data: AACRow | null; error: any } = await sb
  .from("aa_connectors")
  .select("id, aa_joining_code")
  .ilike(col as any, cand)
  .limit(1)
  .maybeSingle();


      if (!ilike.error && ilike.data) {
        return {
          data: {
            id: ilike.data.id,
            referralCode: (ilike.data as any).aa_joining_code,
            source: "aa_connectors",
            matched_col: `${col} (ilike)`,
            matched_value: cand,
          },
          error: null,
          tried: `aa_connectors.${col} (ilike)`,
        };
      } else if (ilike.error && !isUndefinedColumn(ilike.error)) {
        return { data: null as Parent, error: ilike.error, tried: `aa_connectors.${col} (ilike)` };
      }
    }
  }

  return { data: null as Parent, error: null, tried: "none" };
}

// ---------- handler ----------
export default async function handler(req: NextApiRequest, res: NextApiResponse<ApiResponse>) {
  try {
    if (req.method !== "POST") {
      return res.status(405).json({ valid: false, error: "Method not allowed", code: "BAD_REQUEST" });
    }

    let { referralCode, mobile, type, country, state } = (req.body || {}) as Payload;

    if (!referralCode) {
      return res
        .status(400)
        .json({ valid: false, error: "Missing referralCode", code: "BAD_REQUEST" });
    }
    referralCode = referralCode.trim();

    // Allow referral-only checks (no mobile).
const hasMobile = typeof mobile === "string" && mobile.trim() !== "";
// (Normalization uses the top-level toE164 helper where needed)

// ── REFERRAL-ONLY GUARD (STRICT) ────────────────────────────────
if (!hasMobile) {
  if (!referralCode) {
    return res.status(400).json({ valid: false, error: "Missing referralCode", code: "BAD_REQUEST" });
  }
  const mustCountry = (country ?? "").trim();
  const mustState   = (state ?? "").trim();
  if (!mustCountry || !mustState) {
    return res.status(400).json({
      valid: false, code: "BAD_REQUEST",
      error: "Country and State are required for referral validation.",
    });
  }

  // If FE marks this as AA, validate against aa_connectors using DB country/state.
  if (type === "aa") {
    // 1) fetch AA row by code (exact → ilike fallback)
    const exact = await sb
      .from("aa_connectors")
      .select('id, aa_joining_code, "COUNTRY", "STATE"')
      .eq("aa_joining_code", referralCode)
      .limit(1)
      .maybeSingle();

    let aaRow = exact.data;
    if (!aaRow && !exact.error) {
      const ilike = await sb
        .from("aa_connectors")
        .select('id, aa_joining_code, "COUNTRY", "STATE"')
        .ilike("aa_joining_code", referralCode)
        .limit(1)
        .maybeSingle();
      if (ilike.error && !isUndefinedColumn(ilike.error)) {
        return res.status(500).json({ valid: false, error: `[AA ilike] ${describeErr(ilike.error)}`, code: "SERVER_ERROR" });
      }
      aaRow = ilike.data;
    } else if (exact.error && !isUndefinedColumn(exact.error)) {
      return res.status(500).json({ valid: false, error: `[AA exact] ${describeErr(exact.error)}`, code: "SERVER_ERROR" });
    }

    if (!aaRow) {
      return res.status(404).json({ valid: false, error: "REFERRAL CODE INCORRECT", code: "BAD_REFERRAL" });
    }

    // 2) region match (ALL/*/NULL = all states)
    const norm = (s?: string | null) => (s ?? "").toLowerCase().replace(/[\s_-]+/g, "");
    const rowCountry  = norm(aaRow["COUNTRY"]);
    const rowState    = norm(aaRow["STATE"]);
    const wantCountry = norm(mustCountry);
    const wantState   = norm(mustState);

    if (rowCountry !== wantCountry) {
      return res.status(409).json({
        valid: false, code: "COUNTRY_MISMATCH",
        error: `Country mismatch. Referral is for "${aaRow["COUNTRY"]}", got "${mustCountry}".`,
      });
    }

    const isAllStates = !aaRow["STATE"] || rowState === "all" || rowState === "*";
    if (!isAllStates && rowState !== wantState) {
      return res.status(409).json({
        valid: false, code: "STATE_MISMATCH",
        error: `State mismatch. Referral is for "${aaRow["STATE"]}", got "${mustState}".`,
      });
    }

    return res.status(200).json({
      valid: true, code: "OK",
      registeredId: aaRow.id,
      registeredWith: {
        id: String(aaRow.id),
        referralCode: aaRow.aa_joining_code ?? null,
        level: null,
      },
    });
  }

  // Otherwise (child/other referrals), keep your existing behavior (string-implied region).
  const parentLookup = await findParentByReferral(referralCode);

  if (parentLookup.error) {
    return res.status(500).json({
      valid: false,
      error: `[Referral-only lookup via ${parentLookup.tried}] ${describeErr(parentLookup.error)}`,
      code: "SERVER_ERROR",
    });
  }

  if (!parentLookup.data) {
    return res.status(404).json({
      valid: false,
      error: "REFERRAL CODE INCORRECT",
      code: "BAD_REFERRAL",
    });
  }

  const { refCountry, refState } = parseCSFromReferral(referralCode);

  if (refCountry && !same(mustCountry, refCountry)) {
    return res.status(409).json({
      valid: false,
      code: "COUNTRY_MISMATCH",
      error: `Country mismatch. Referral implies "${refCountry}", got "${mustCountry}".`,
    });
  }

  const isAll = /^(all|allstates|all_states)$/i.test(mustState.replace(/\s+/g, ""));
  if (refState && !isAll && !same(mustState, refState)) {
    return res.status(409).json({
      valid: false,
      code: "STATE_MISMATCH",
      error: `State mismatch. Referral implies "${refState}", got "${mustState}".`,
    });
  }

  return res.status(200).json({
    valid: true,
    code: "OK",
    registeredId: parentLookup.data.id, // allowed: string | number
    registeredWith: {
      id: String(parentLookup.data.id), // <- force to string
      referralCode: parentLookup.data.referralCode ?? null,
      level: null,
    },
  });
}
// ────────────────────────────────────────────────────────────────


    // Mobile path requires type
    if (!type) {
      return res
        .status(400)
        .json({ valid: false, error: "Missing type", code: "BAD_REQUEST" });
    }

if (type === "aa") {
  if (!referralCode) {
    return res.status(400).json({ valid: false, error: "Missing referralCode", code: "BAD_REQUEST" });
  }
  if (!hasMobile) {
    return res.status(400).json({ valid: false, error: "Missing mobile for AA", code: "BAD_REQUEST" });
  }
  if (!country) {
    return res.status(400).json({ valid: false, error: "Missing country for AA", code: "BAD_REQUEST" });
  }

  const mobileE164 = toE164(String(mobile || ""));

  // Pull candidates for (code + normalized mobile + country)
  const { data, error } = await sb
    .from("aa_connectors")
    .select('id, aa_joining_code, "COUNTRY", "STATE"')
    .eq("aa_joining_code", referralCode)
    .eq("mobile", mobileE164)
    .eq("COUNTRY", country)
    .limit(10);

  if (error) {
    return res.status(500).json({ valid: false, error: `[AA code+mobile] ${describeErr(error)}`, code: "SERVER_ERROR" });
  }

  // Apply state rule: row.STATE null/ALL/* = wildcard; otherwise must match selected state
  const wantState = (state ?? "").trim();
  const norm = (s?: string | null) => (s ?? "").toLowerCase().replace(/[\s_-]+/g, "");
  const wantStateNorm = norm(wantState);

  const matched = (data || []).some((row: any) => {
    const rowState = row?.["STATE"] ?? null;
    const rs = norm(rowState);
    const isAll = rowState == null || rs === "all" || rs === "*";
    if (!wantState) return true;                 // country-only path allowed
    if (wantStateNorm === "allstates") return isAll;
    return isAll || rs === wantStateNorm;
  });

  if (!matched) {
    return res.status(200).json({
      valid: false,
      error: "MOBILE NUMBER NOT REGISTERED - UNABLE TO JOIN AS AA CONNECTOR",
      code: "BAD_REQUEST",
    });
  }

  return res.status(200).json({ valid: true, code: "OK" });
}


    if (type === "child") {
      // Parent referral exists?
      const parentLookup = await findParentByReferral(referralCode);
      if (parentLookup.error) {
        return res.status(500).json({
          valid: false,
          error: `[Child parent via ${parentLookup.tried}] ${describeErr(parentLookup.error)}`,
          code: "SERVER_ERROR",
        });
      }
      if (!parentLookup.data) {
        return res.status(404).json({
          valid: false,
          error: "REFERRAL CODE INCORRECT",
          code: "BAD_REFERRAL",
        });
      }

      // Is mobile already used by any connector?
     const { data: existingRow, error: existingErr }: {
  data: { id: string | number; referralCode?: string | null; level?: string | null } | null;
  error: any;
} = await sb
  .from("connectors")
  .select("id, referralCode, level")
  .eq(MOBILE_COL, mobile)
  .limit(1)
  .maybeSingle();


      if (existingErr) {
        return res.status(500).json({
          valid: false,
          error: `[Child existing row] ${describeErr(existingErr)}`,
          code: "SERVER_ERROR",
        });
      }

      if (existingRow) {
        // Compare duplicate's referralCode with matched parent referralCode
        const parentCode = (parentLookup.data as any)?.referralCode ?? null;
        const existingCode = (existingRow as any)?.referralCode ?? null;
        const sameTree = parentCode && existingCode && String(parentCode) === String(existingCode);

        if (sameTree) {
         return res.status(409).json({
  valid: false,
  code: "MOBILE_ALREADY_ON_TREE",
  message: `This mobile is already registered under ${existingCode}.`,
  error: `This mobile is already registered under ${existingCode}.`,
  registeredId: existingCode, // string | number is fine
  registeredWith: {
    id: String(existingRow.id), // <- force to string
    referralCode: existingCode,
    level: (existingRow as any).level ?? null,
  },
});

        }

       return res.status(409).json({
  valid: false,
  code: "MOBILE_BELONGS_TO_OTHER",
  message: `This mobile is already registered under ${existingCode}. Use that referral or a different mobile.`,
  error: `This mobile is already registered under ${existingCode}. Use that referral or a different mobile.`,
  registeredId: existingCode, // string | number is fine
  registeredWith: {
    id: String(existingRow.id), // <- force to string
    referralCode: existingCode,
    level: (existingRow as any).level ?? null,
  },
});

      }

      return res.status(200).json({ valid: true, code: "OK" });
    }

    return res.status(400).json({ valid: false, error: "Invalid type", code: "BAD_REQUEST" });
  } catch (err) {
    console.error("[BE] Unexpected error:", err);
    return res.status(500).json({ valid: false, error: "Internal server error", code: "SERVER_ERROR" });
  }
}
