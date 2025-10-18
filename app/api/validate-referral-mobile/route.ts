/* eslint-disable @typescript-eslint/no-explicit-any */
// File: app/api/validate-referral-mobile/route.ts
import { NextResponse } from "next/server";
import { createClient, PostgrestError } from "@supabase/supabase-js";

// Ensure Node runtime (supabase-js requires Node, not Edge)
export const runtime = "nodejs";
export const dynamic = "force-dynamic";

/* ---------------------------- Supabase (server) ---------------------------- */

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const supabase = createClient(supabaseUrl, supabaseServiceKey);
// Use any-typed alias to avoid deep TS generics inside this file
const sb = supabase as any;

/* --------------------------------- Config --------------------------------- */

const MOBILE_COL: "mobile" | "mobile_number" | "mobile_e164" = "mobile_number";

/* -------------------------------- Helpers --------------------------------- */

type AACRow = { id: string | number; aa_joining_code: string | null };

function describeErr(err?: PostgrestError | null) {
  if (!err) return "";
  const parts = [err.code, err.message, err.details, err.hint].filter(Boolean).map(String);
  return parts.join(" | ") || JSON.stringify(err);
}
function isUndefinedColumn(err?: PostgrestError | null) {
  return !!err && (err.code === "42703" || /column .* does not exist/i.test(err.message || ""));
}
function toE164(m: string) {
  const digits = String(m || "").replace(/[^\d]/g, "");
  return digits ? `+${digits}` : "";
}
function normalizeSpaces(s: string) {
  return (s || "").replace(/\s+/g, " ").trim();
}
function toUnderscore(s: string) {
  return normalizeSpaces(s).replace(/\s/g, "_");
}
function stripTrailingGeneration(code: string) {
  return (code || "").replace(/_[A-Za-z0-9]+$/, "");
}
function unique<T>(arr: T[]) {
  return Array.from(new Set(arr));
}
function fixKnownTypos(s: string) {
  let x = s || "";
  x = x.replace(/BDDH[’'`a]+(?=\d)/gi, "BDDH_");
  x = x.replace(/\\(?=\d)/g, "_");
  x = x.replace(/_+/g, "_");
  return x;
}
function quoteVariants(s: string) {
  const apostrophe = s.replace(/[\u2018\u2019\u201B]/g, "'");
  const backtick = s.replace(/[\u2018\u2019\u201B']/g, "`");
  const stripped = s.replace(/[\u2018\u2019\u201B'`]/g, "");
  return [s, apostrophe, backtick, stripped];
}
function buildReferralVariants(raw: string) {
  const baseInputs = unique([raw.trim(), fixKnownTypos(raw.trim())]);
  const shaped = baseInputs.flatMap((o) => [o, normalizeSpaces(o), toUnderscore(o)]);
  const withQuotes = shaped.flatMap(quoteVariants);
  const plusNoGen = withQuotes.flatMap((v) => [v, stripTrailingGeneration(v)]);
  return unique(plusNoGen).filter(Boolean);
}
function same(a?: string | null, b?: string | null) {
  const norm = (s?: string | null) => (s || "").toLowerCase().replace(/[\s_-]+/g, "");
  return norm(a) === norm(b);
}
function parseCSFromReferral(code: string) {
  const fixed = fixKnownTypos(code);
  const [refCountry, refState] = fixed.split("_").slice(0, 2).map((s) => (s || "").trim());
  return { refCountry, refState };
}
const AA_SEED_PATTERN = /^[A-Za-z]+(?:[_\s][A-Za-z]+)*(?:[_\s]M\d+)$/i;
const isAASeed = (code: string) => AA_SEED_PATTERN.test((code || "").trim());
const norm = (s?: string | null) => (s ?? "").toLowerCase().replace(/[\s_-]+/g, "");
const isAllStateToken = (s: string) => /^(all|allstates|all_states|\*)$/i.test((s || "").replace(/\s+/g, ""));

/* -------------- Robust parent referral finder (legacy parity) -------------- */

async function findParentByReferral(referralCode: string) {
  type Parent =
    | {
        id: string;
        referralCode?: string | null;
        source: "connectors" | "aa_connectors";
        matched_col: string;
        matched_value: string;
      }
    | null;

  const candidates = buildReferralVariants(referralCode);

  // 1) connectors.referralCode (exact → ilike)
  for (const cand of candidates) {
    const exact: { data: { id: string | number; referralCode?: string | null } | null; error: any } =
      await sb.from("connectors").select("id, referralCode").eq("referralCode", cand).limit(1).maybeSingle();

    if (exact.error && !isUndefinedColumn(exact.error)) {
      return { data: null as Parent, error: exact.error, tried: "connectors.referralCode" };
    }
    if (exact.data) {
      return {
        data: {
          id: String(exact.data.id),
          referralCode: (exact.data as any).referralCode,
          source: "connectors",
          matched_col: "referralCode",
          matched_value: cand,
        },
        error: null,
        tried: "connectors.referralCode",
      };
    }

    const ilike: { data: { id: string | number; referralCode?: string | null } | null; error: any } =
      await sb.from("connectors").select("id, referralCode").ilike("referralCode", cand).limit(1).maybeSingle();

    if (!ilike.error && ilike.data) {
      return {
        data: {
          id: String(ilike.data.id),
          referralCode: (ilike.data as any).referralCode,
          source: "connectors",
          matched_col: "referralCode (ilike)",
          matched_value: cand,
        },
        error: null,
        tried: "connectors.referralCode (ilike)",
      };
    } else if (ilike.error && !isUndefinedColumn(ilike.error)) {
      return { data: null as Parent, error: ilike.error, tried: "connectors.referralCode (ilike)" };
    }
  }

  // 2) aa_connectors.(aa_joining_code | connector_code) (exact → ilike)
  const aaCols = ["aa_joining_code", "connector_code"] as const;
  for (const cand of candidates) {
    for (const col of aaCols) {
      const exact: { data: AACRow | null; error: any } = await sb
        .from("aa_connectors")
        .select("id, aa_joining_code")
        .eq(col as any, cand)
        .limit(1)
        .maybeSingle();

      if (exact.error) {
        if (!isUndefinedColumn(exact.error)) {
          return { data: null as Parent, error: exact.error, tried: `aa_connectors.${col}` };
        }
      } else if (exact.data) {
        return {
          data: {
            id: String(exact.data.id),
            referralCode: (exact.data as any).aa_joining_code,
            source: "aa_connectors",
            matched_col: String(col),
            matched_value: cand,
          },
          error: null,
          tried: `aa_connectors.${col}`,
        };
      }

      const ilike: { data: AACRow | null; error: any } = await sb
        .from("aa_connectors")
        .select("id, aa_joining_code")
        .ilike(col as any, cand)
        .limit(1)
        .maybeSingle();

      if (!ilike.error && ilike.data) {
        return {
          data: {
            id: String(ilike.data.id),
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

/* ------------------------------ Route handler ------------------------------ */

export async function POST(req: Request) {
  try {
    const body = (await req.json()) ?? {};
    let { referralCode, mobile, type, country, state } = body as {
      referralCode?: string;
      mobile?: string;
      type?: "aa" | "child";
      country?: string | null;
      state?: string | null;
    };

    // Basic input
    if (!referralCode) {
      return NextResponse.json(
        { valid: false, error: "Missing referralCode", code: "BAD_REQUEST" },
        { status: 400 }
      );
    }
    referralCode = referralCode.trim();

    // Referral-only?
    const hasMobile = typeof mobile === "string" && mobile.trim() !== "";
    const mustCountry = String(country ?? "").trim();
    const mustState = String(state ?? "").trim();

    /* =========================== REFERRAL-ONLY =========================== */
    if (!hasMobile) {
      if (!mustCountry || !mustState) {
        return NextResponse.json(
          {
            valid: false,
            code: "BAD_REQUEST",
            error: "Country and State are required for referral validation.",
          },
          { status: 400 }
        );
      }

      const stepType = (type ?? (isAASeed(referralCode) ? "aa" : "child")) as "aa" | "child";

      if (stepType === "aa") {
        // AA: fetch by code and enforce region match; STATE null/*/ALL = wildcard
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
            return NextResponse.json(
              { valid: false, error: `[AA ilike] ${describeErr(ilike.error)}`, code: "SERVER_ERROR" },
              { status: 500 }
            );
          }
          aaRow = ilike.data;
        } else if (exact.error && !isUndefinedColumn(exact.error)) {
          return NextResponse.json(
            { valid: false, error: `[AA exact] ${describeErr(exact.error)}`, code: "SERVER_ERROR" },
            { status: 500 }
          );
        }

        if (!aaRow) {
          return NextResponse.json(
            { valid: false, error: "REFERRAL CODE INCORRECT", code: "BAD_REFERRAL" },
            { status: 404 }
          );
        }

        if (norm(aaRow["COUNTRY"]) !== norm(mustCountry)) {
          return NextResponse.json(
            {
              valid: false,
              code: "COUNTRY_MISMATCH",
              error: `Country mismatch. Referral is for "${aaRow["COUNTRY"]}", got "${mustCountry}".`,
            },
            { status: 409 }
          );
        }

        const rowState = String(aaRow["STATE"] ?? "");
        const wildcard = !rowState || isAllStateToken(rowState);
        if (!wildcard && norm(rowState) !== norm(mustState)) {
          return NextResponse.json(
            {
              valid: false,
              code: "STATE_MISMATCH",
              error: `State mismatch. Referral is for "${aaRow["STATE"]}", got "${mustState}".`,
            },
            { status: 409 }
          );
        }

        return NextResponse.json({
          valid: true,
          code: "OK",
          registeredId: aaRow.id,
          registeredWith: {
            id: String(aaRow.id),
            referralCode: aaRow.aa_joining_code ?? null,
            level: null,
          },
        });
      }

      // child: parent referral exists?
      const parentLookup = await findParentByReferral(referralCode);
      if (parentLookup.error) {
        return NextResponse.json(
          {
            valid: false,
            error: `[Referral-only lookup via ${parentLookup.tried}] ${describeErr(parentLookup.error)}`,
            code: "SERVER_ERROR",
          },
          { status: 500 }
        );
      }
      if (!parentLookup.data) {
        return NextResponse.json(
          { valid: false, error: "REFERRAL CODE INCORRECT", code: "BAD_REFERRAL" },
          { status: 404 }
        );
      }

      // Optional: implicit country/state checks using parsed tokens
      const { refCountry, refState } = parseCSFromReferral(referralCode);
      if (refCountry && !same(mustCountry, refCountry)) {
        return NextResponse.json(
          {
            valid: false,
            code: "COUNTRY_MISMATCH",
            error: `Country mismatch. Referral implies "${refCountry}", got "${mustCountry}".`,
          },
          { status: 409 }
        );
      }
      const isAll = /^(all|allstates|all_states)$/i.test(mustState.replace(/\s+/g, ""));
      if (refState && !isAll && !same(mustState, refState)) {
        return NextResponse.json(
          {
            valid: false,
            code: "STATE_MISMATCH",
            error: `State mismatch. Referral implies "${refState}", got "${mustState}".`,
          },
          { status: 409 }
        );
      }

      return NextResponse.json({
        valid: true,
        code: "OK",
        registeredId: parentLookup.data.id,
        registeredWith: {
          id: String(parentLookup.data.id),
          referralCode: parentLookup.data.referralCode ?? null,
          level: null,
        },
      });
    }
    /* ========================= END REFERRAL-ONLY ========================= */

    // From here on, mobile path requires `type`
    if (!type) {
      return NextResponse.json(
        { valid: false, error: "Missing type", code: "BAD_REQUEST" },
        { status: 400 }
      );
    }

    /* ============================== AA + mobile ============================== */
    if (type === "aa") {
      if (!referralCode) {
        return NextResponse.json(
          { valid: false, error: "Missing referralCode", code: "BAD_REQUEST" },
          { status: 400 }
        );
      }
      if (!hasMobile) {
        return NextResponse.json(
          { valid: false, error: "Missing mobile for AA", code: "BAD_REQUEST" },
          { status: 400 }
        );
      }
      if (!country) {
        return NextResponse.json(
          { valid: false, error: "Missing country for AA", code: "BAD_REQUEST" },
          { status: 400 }
        );
      }

      const mobileE164 = toE164(String(mobile || ""));

      // code + mobile + country (state handled as wildcard)
      const { data, error } = await sb
        .from("aa_connectors")
        .select('id, aa_joining_code, "COUNTRY", "STATE"')
        .eq("aa_joining_code", referralCode)
        .eq("mobile", mobileE164)
        .eq("COUNTRY", country)
        .limit(10);

      if (error) {
        return NextResponse.json(
          { valid: false, error: `[AA code+mobile] ${describeErr(error)}`, code: "SERVER_ERROR" },
          { status: 500 }
        );
      }

      const wantState = (state ?? "").trim();
      const wantStateNorm = norm(wantState);

      const matched = (data || []).some((row: any) => {
        const rowState = row?.["STATE"] ?? null;
        const rs = norm(rowState);
        const isAll = rowState == null || rs === "all" || rs === "*";
        if (!wantState) return true; // country-only allowed
        if (wantStateNorm === "allstates") return isAll;
        return isAll || rs === wantStateNorm;
      });

      if (!matched) {
        return NextResponse.json(
          {
            valid: false,
            error: "MOBILE NUMBER NOT REGISTERED - UNABLE TO JOIN AS AA CONNECTOR",
            code: "BAD_REQUEST",
          },
          { status: 200 }
        );
      }

      return NextResponse.json({ valid: true, code: "OK" });
    }

    /* ============================ child + mobile ============================ */
    if (type === "child") {
      // Parent referral exists?
      const parentLookup = await findParentByReferral(referralCode);
      if (parentLookup.error) {
        return NextResponse.json(
          {
            valid: false,
            error: `[Child parent via ${parentLookup.tried}] ${describeErr(parentLookup.error)}`,
            code: "SERVER_ERROR",
          },
          { status: 500 }
        );
      }
      if (!parentLookup.data) {
        return NextResponse.json(
          { valid: false, error: "REFERRAL CODE INCORRECT", code: "BAD_REFERRAL" },
          { status: 404 }
        );
      }

      // Duplicate check on connectors.<MOBILE_COL>
      const existing: {
        data: { id: string | number; referralCode?: string | null; level?: string | null } | null;
        error: any;
      } = await sb
        .from("connectors")
        .select("id, referralCode, level")
        .eq(MOBILE_COL, mobile)
        .limit(1)
        .maybeSingle();

      if (existing.error) {
        return NextResponse.json(
          { valid: false, error: `[Child existing row] ${describeErr(existing.error)}`, code: "SERVER_ERROR" },
          { status: 500 }
        );
      }

      if (existing.data) {
        const parentCode = (parentLookup.data as any)?.referralCode ?? null;
        const existingCode = (existing.data as any)?.referralCode ?? null;
        const sameTree = parentCode && existingCode && String(parentCode) === String(existingCode);

        if (sameTree) {
          return NextResponse.json(
            {
              valid: false,
              code: "MOBILE_ALREADY_ON_TREE",
              message: `This mobile is already registered under ${existingCode}.`,
              error: `This mobile is already registered under ${existingCode}.`,
              registeredId: existingCode,
              registeredWith: {
                id: String(existing.data.id),
                referralCode: existingCode,
                level: (existing.data as any).level ?? null,
              },
            },
            { status: 409 }
          );
        }

        return NextResponse.json(
          {
            valid: false,
            code: "MOBILE_BELONGS_TO_OTHER",
            message: `This mobile is already registered under ${existingCode}. Use that referral or a different mobile.`,
            error: `This mobile is already registered under ${existingCode}. Use that referral or a different mobile.`,
            registeredId: existingCode,
            registeredWith: {
              id: String(existing.data.id),
              referralCode: existingCode,
              level: (existing.data as any).level ?? null,
            },
          },
          { status: 409 }
        );
      }

      return NextResponse.json({ valid: true, code: "OK" });
    }

    return NextResponse.json(
      { valid: false, error: "Invalid type", code: "BAD_REQUEST" },
      { status: 400 }
    );
  } catch (err: any) {
    console.error("[BE] Unexpected error:", err);
    return NextResponse.json(
      { valid: false, error: "Internal server error", code: "SERVER_ERROR" },
      { status: 500 }
    );
  }
}

/* Optional: answer GET with 405 to match legacy behavior */
export async function GET() {
  return NextResponse.json({ error: "Method not allowed" }, { status: 405 });
}
