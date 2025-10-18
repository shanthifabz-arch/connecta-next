"use client";

import { useSearchParams } from "next/navigation";
import { useState, useEffect, useRef, useMemo } from "react";
import { useCountryStateOptions } from "@/hooks/useCountryStateOptions";
import "@/lib/i18n";
import { useTranslation } from "react-i18next";
import Link from "next/link";
import { validatePincode } from "@/utils/pincode";
import { supabase } from "@/lib/supabaseClient";
import { useRouter } from "next/navigation";
import { PhoneSummary, RegionLangSummary } from "@/components/ui/SummaryRows";

// Country dialing prefixes (fallback if ?prefix= not present)
const countryPrefixes: Record<string, string> = {
  India: "+91",
  Bangladesh: "+880",
  USA: "+1",
};
// Local number length rules (digits AFTER the country code)
const localDigitsRequired: Record<string, number> = {
  India: 10,
  USA: 10,
  Bangladesh: 10,
};

// Build a friendly option label, e.g. "Bangla (বাংলা) — BN-BD"
function labelForLang(l: any) {
  const name = String(l?.display_name || l?.label || l?.code || "").trim();
  const code = String(l?.code || "").trim();
  return code ? `${name} — ${code.toUpperCase()}` : name;
}
// Canonicalize language codes to "xx" or "xx-yy"
const canonLang = (code: string) =>
  String(code || "").trim().toLowerCase().replace(/_/g, "-");

// Human label fallback
const codeToReadableName: Record<string, string> = {
  en: "English",
  ta: "Tamil",
  hi: "Hindi",
  bn: "Bengali",
};

// Country code → flag emoji
function countryCodeToFlagEmoji(cc?: string) {
  const code = String(cc || "").toUpperCase();
  if (!/^[A-Z]{2}$/.test(code)) return "";
  const BASE = 0x1f1e6;
  return String.fromCodePoint(
    ...code.split("").map((c) => BASE + (c.charCodeAt(0) - 65))
  );
}

// Try to infer country from a language object or a raw code string
function inferCountryForCodeOrLang(l: any): string | null {
  const direct = l?.country_code || l?.country || "";
  if (typeof direct === "string" && /^[A-Za-z]{2}$/.test(direct))
    return direct.toUpperCase();

  const code = canonLang(l?.code || l || "");
  const parts = code.split("-");
  if (parts[1] && /^[a-z]{2}$/i.test(parts[1])) return parts[1].toUpperCase();

  const base = parts[0];
  const map: Record<string, string> = { id: "ID", bn: "BD", ta: "IN", hi: "IN", ur: "PK" };
  return map[base] || null;
}

// Single source of truth for language label
const uniformLabel = (l: any) =>
  String(l?.display_name || l?.label || l?.code || "").toString().trim() ||
  (l?.code ? l.code.toUpperCase() : "");

// Return local-digit count from a full E.164-like string using the known prefix
function localDigitsCount(e164: string, prefix: string) {
  const cc = String(prefix || "").replace(/\D/g, "");
  const all = String(e164 || "").replace(/\D/g, "");
  return all.startsWith(cc) ? all.slice(cc.length).length : all.length;
}

type FieldName =
  | "fullName"
  | "profession"
  | "addressLine1"
  | "addressLine2"
  | "addressLine3"
  | "city"
  | "pincode"
  | "email";

const FIELD_LABELS: Record<FieldName, string> = {
  fullName: "Full Name",
  profession: "Profession",
  addressLine1: "Address Line - 1",
  addressLine2: "Address Line - 2",
  addressLine3: "Address Line - 3",
  city: "City",
  pincode: "Pincode",
  email: "Email",
};

const FIELD_ORDER: FieldName[] = [
  "fullName",
  "profession",
  "addressLine1",
  "addressLine2",
  "addressLine3",
  "city",
  "pincode",
  "email",
];

// ── AA helpers ────────────────────────────────────────────────────────────────
const canon = (s: string) => String(s || "").trim().toLowerCase();

async function resolveAAParentOrThrow(
  ref: string,
  selectedCountry: string,
  selectedState: string
): Promise<{ country: string; state: string; aaStateLock: boolean }> {
  const { data: rows, error } = await supabase
    .from("aa_connectors")
    .select("*")
    .eq("aa_joining_code", ref);

  if (error) throw new Error(error.message);
  if (!rows || rows.length === 0) {
    throw new Error("AA code not found");
  }

  const records = rows.map((r: any) => ({
    row: r,
    country: String(
      r.country ?? r.COUNTRY ?? r.country_name ?? r.COUNTRY_NAME ?? ""
    ).trim(),
    state: String(
      r.state ?? r.STATE ?? r.state_name ?? r.STATE_NAME ?? ""
    ).trim(),
  }));

  const byCountry = records.filter(
    (r) => canon(r.country) === canon(selectedCountry)
  );
  if (byCountry.length === 0) {
    throw new Error("This AA code is not valid for the selected country.");
  }

  const isAllStates = (s: string) =>
    canon(s).replace(/\s+/g, "") === "allstates" || s === "";

  const exactState = byCountry.filter(
    (r) => canon(r.state) === canon(selectedState)
  );
  const allStates = byCountry.filter((r) => isAllStates(r.state));

  const newestFirst = (a: any, b: any) => {
    const ad =
      new Date(a.row?.created_at || a.row?.createdAt || 0).getTime() || 0;
    const bd =
      new Date(b.row?.created_at || b.row?.createdAt || 0).getTime() || 0;
    return bd - ad;
  };

  let pick: (typeof records)[number] | null = null;

  if (exactState.length > 0) {
    exactState.sort(newestFirst);
    pick = exactState[0];
  } else if (allStates.length > 0) {
    allStates.sort(newestFirst);
    pick = allStates[0];
  } else {
    throw new Error("This AA code is not valid for the selected state.");
  }

  const aaCountry = pick.country || selectedCountry;
  const aaState = pick.state || selectedState;
  const lockState = !isAllStates(aaState);

  return {
    country: aaCountry,
    state: lockState ? aaState : selectedState,
    aaStateLock: lockState,
  };
}

function padINTA(ref: string): string {
  const re = /(.*_INTA[A-Z]{2})(\d+)(.*)$/i;
  const m = (ref || "").trim().match(re);
  if (!m) return ref;
  const [_, head, digits, tail] = m;
  return `${head}${digits.padStart(9, "0")}${tail}`;
}


// --- Helper: parse parent level from referral (e.g. INTAAD000000002 -> AD)
function extractParentLevelFromRef(ref: string): string | null {
  const s = String(ref || "").toUpperCase();
  const m = s.match(/[A-Z]{4}([A-Z]{2})\d+/);
  return m ? m[1] : null;
}

// --- Helper: infer country/state from the referral code ---
const normalize = (s: string) =>
  s
    .toLowerCase()
    .replace(/[_-]+/g, " ")
    .replace(/[^\p{L}\p{N}\s]/gu, " ")
    .replace(/\s+/g, " ")
    .trim();

function parseReferralToSuggestion(
  ref: string,
  countries: string[],
  statesByCountry: Record<string, string[]>
): { country: string; state: string } | null {
  const text = normalize(ref);
  if (!text) return null;

  const countryMap = new Map<string, string>();
  for (const c of countries) countryMap.set(normalize(c), c);

  let foundCountry: string | null = null;
  for (const [key, display] of countryMap.entries()) {
    if (key && text.includes(key)) {
      foundCountry = display;
      break;
    }
  }
  if (!foundCountry) return null;

  const states = statesByCountry[foundCountry] || [];
  let foundState: string | null = null;

  if (states.length) {
    for (const raw of states) {
      const key = normalize(typeof raw === "string" ? raw : String(raw));
      if (key && text.includes(key)) {
        foundState = typeof raw === "string" ? raw : String(raw);
        break;
      }
    }
  }

  return { country: foundCountry, state: foundState ?? "All States" };
}

// —— Language helpers ——
function sortLangs(arr: any[]) {
  return [...(arr || [])].sort((a, b) =>
    String(a?.display_name || a?.label || a?.code || "").localeCompare(
      String(b?.display_name || b?.label || b?.code || "")
    )
  );
}

function dedupeBy<T>(arr: T[], getKey: (x: T) => string) {
  const seen = new Set<string>();
  const out: T[] = [];
  for (const item of arr || []) {
    const k = getKey(item);
    if (!k || seen.has(k)) continue;
    seen.add(k);
    out.push(item);
  }
  return out;
}

function computeSafeLangs(raw: any[]) {
  const normalized = (raw || []).map((l) => ({
    ...l,
    code: String(l?.code || "").trim(),
    display_name: String(l?.display_name || l?.label || "").trim(),
  }));
  let safe = dedupeBy(normalized, (l: any) => l.code.toLowerCase());
  safe = dedupeBy(
    safe,
    (l: any) =>
      `${l.code.toLowerCase().split("-")[0]}|${(l.display_name || "").toLowerCase()}`
  );
  return sortLangs(safe);
}

// --- DB helper: get parent level by referral (ONE source of truth) ---
async function fetchParentLevelByReferral(code: string) {
  const { data, error } = await supabase
    .from("connectors")
    .select("level")
    .eq("referralCode", code)
    .maybeSingle();

  if (error) {
    console.warn("[child] parent lookup failed:", error.message);
    return null;
  }
  return data?.level ? String(data.level).toUpperCase() : null;
}

// --- Normalize phone to E.164-like
function normalizePhone(raw: string) {
  const s = String(raw || "").trim();
  let cleaned = s.replace(/[^0-9+]/g, "");
  if (cleaned.startsWith("00")) cleaned = "+" + cleaned.slice(2);
  cleaned = cleaned.replace(/(?!^)\+/g, "");
  return cleaned;
}

// --- Next double-letter helper (AA->AB->...->AZ->BA...)
function nextAlphaPair(input: string): string {
  if (!/^[A-Z]{2}$/i.test(input)) return "AA";
  const chars = input.toUpperCase().split("");
  let [first, second] = chars.map((c) => c.charCodeAt(0));
  if (second < 90) {
    second += 1;
  } else {
    second = 65; // 'A'
    if (first < 90) first += 1;
    else first = 65; // wrap ZZ->AA
  }
  return String.fromCharCode(first) + String.fromCharCode(second);
}

/* === UI hygiene helpers (Step 7) === */
function normalizeEmail(email: string) {
  const s = (email || "").trim();
  return s ? s.toLowerCase() : s;
}

function normalizeUpi(upi: string) {
  const s = (upi || "").trim();
  return s ? s.toLowerCase() : s;
}

function withHttps(url: string) {
  const s = (url || "").trim();
  if (!s) return s;
  return /^https?:\/\//i.test(s) ? s : `https://${s}`;
}

function isLikelyUrl(text: string) {
  return /(https?:\/\/|www\.)/i.test(text || "");
}

function sanitizeProducts(products: Array<{ description?: string; [k: string]: any }>) {
  return (products || []).map((p) => {
    const d = (p?.description || "").trim();
    return isLikelyUrl(d) ? { ...p, description: "" } : p;
  });
}

function deriveShortName(fullName: string, provided?: string) {
  const chosen = (provided || "").trim() || (fullName || "").trim();
  return chosen.slice(0, 14);
}


// --- Safely fetch existing connector by mobile (tries OR, falls back to EQ)
async function fetchExistingByMobile(e164: string) {
  // First try OR across mobile_number and mobile_e164
  let q = await supabase
    .from("connectors")
    .select("id, referralCode, referral_code, country, state, global_connecta_id")
    .or(`mobile_number.eq.${e164},mobile_e164.eq.${e164}`)
    .limit(1)
    .maybeSingle();

  if (q.error) {
    // Fallback: some schemas don't have mobile_e164
    q = await supabase
      .from("connectors")
      .select("id, referralCode, referral_code, country, state, global_connecta_id")
      .eq("mobile_number", e164)
      .limit(1)
      .maybeSingle();
  }

  return q;
}


export default function OnboardingTabs() {
  const searchParams = useSearchParams();
  const allowConnectors = (searchParams?.get("allowConnectors") ?? "1") === "1";

 const buildHref = (variant: "b2c" | "b2b" | "import" | "export") => {
  const keys = [
    "ref",
    "country",
    "state",
    "mobile",
    "recoveryMobile",
    "lang",
    "langLabel",
    "prefix",
  ];

  const qs = new URLSearchParams();
  keys.forEach((k) => {
    const v = searchParams?.get(k) ?? null; // ← null-safe
    if (v) qs.set(k, v);
  });

  return `/${variant}?${qs.toString()}`;
};


  const { t, i18n } = useTranslation();
  const router = useRouter();

  const [translations, setTranslations] = useState<Record<string, string>>({});
  const tOverride = (key: string) => translations[key] || t(key);

  // URL params
  const referralCode = searchParams?.get("ref") ?? "";
  const qrCountry = searchParams?.get("country") ?? "";
  const qrState = searchParams?.get("state") ?? "";
  const selectedLangCode = searchParams?.get("lang") ?? "";
  const langLabelFromURL =
    searchParams?.get("langLabel") ?? t("select_language");
  const mobileNumberFromURL = searchParams?.get("mobile") ?? "";
  const prefixFromURL =
    searchParams?.get("prefix") ?? countryPrefixes[qrCountry] ?? "";

    const canonicalRef = useMemo(
  () => padINTA((referralCode || "").trim()),
  [referralCode]
);


  // Optional params
  const otpFromURL = (searchParams?.get("otp") ?? "0") === "1";

  // Recovery mobile (URL → typed split)
  const recoveryMobileFromURLRaw = (searchParams?.get("recoveryMobile") ?? "").trim();

  const initialRecoveryLocal = recoveryMobileFromURLRaw
    ? recoveryMobileFromURLRaw.startsWith(prefixFromURL || "")
      ? recoveryMobileFromURLRaw.slice((prefixFromURL || "").length)
      : recoveryMobileFromURLRaw.replace(/^\+/, "")
    : "";

  const recoveryFromURL = recoveryMobileFromURLRaw
    ? recoveryMobileFromURLRaw.startsWith("+")
      ? recoveryMobileFromURLRaw
      : (prefixFromURL || "") + recoveryMobileFromURLRaw
    : "";

  // Invite path
  const invitePathRaw =
    searchParams?.get("invitePath") ??
    process.env.NEXT_PUBLIC_INVITE_PATH ??
    "/welcome";
  const invitePath =
    invitePathRaw?.startsWith("/") ? invitePathRaw : `/${invitePathRaw}`;

  // Dup check controls
  const skipDupCheck =
    (searchParams?.get("dup") ?? "") === "skip" ||
    process.env.NEXT_PUBLIC_DEV_SKIP_DUP === "1";

  const dupSourceParam = (
    searchParams?.get("dupSource") ??
    process.env.NEXT_PUBLIC_DUP_SOURCE ??
    (process.env.NODE_ENV !== "production" ? "typed" : "url")
  )
    .toString()
    .toLowerCase();

  const isAAConnector = qrCountry !== "" && qrState !== "";
  const [referralSuggestion, setReferralSuggestion] =
    useState<{ country: string; state: string } | null>(null);

  const lockCountry = isAAConnector;
  const lockState =
    isAAConnector && (qrState || "").trim().toLowerCase() !== "all states";

  // Country/State options
  const { countries, statesByCountry } = useCountryStateOptions();

  // Language state
  const [languageOptions, setLanguageOptions] = useState<any[]>([]);
  const [selectedLanguage, setSelectedLanguage] = useState<string>("");
  const [langQuery, setLangQuery] = useState("");
  const [showLangFilter, setShowLangFilter] = useState(false);
  const fetchedLangsRef = useRef(false);
  const initLangRef = useRef(false);

  const filteredLangs = useMemo(() => {
    const q = langQuery.trim().toLowerCase();
    if (!q) return languageOptions;
    return (languageOptions || []).filter((l: any) => {
      const label = (uniformLabel(l) || "").toLowerCase();
      const code = String(l?.code || "").toLowerCase();
      return label.includes(q) || code.includes(q);
    });
  }, [langQuery, languageOptions]);

  // UI state
  const [submitted, setSubmitted] = useState(false);
  const [generatedReferral, setGeneratedReferral] = useState("");
  const [inviteLink, setInviteLink] = useState("");

  // One-time seed of selected language
  useEffect(() => {
    if (initLangRef.current) return;

    const qp = canonLang(selectedLangCode || "");
    const ls =
      typeof window !== "undefined"
        ? canonLang(localStorage.getItem("language") || "")
        : "";
    const i18nLang = canonLang(i18n?.language || "");
    const current = qp || ls || i18nLang || "en";

    if (current) {
      setSelectedLanguage(current);
      try {
        i18n?.changeLanguage?.(current);
      } catch {}
      if (typeof window !== "undefined")
        localStorage.setItem("language", current);
    }

    initLangRef.current = true;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    const effectiveLang = selectedLanguage || selectedLangCode;
    if (!effectiveLang) return;

    (async () => {
      const { data, error } = await supabase
        .from("translations")
        .select("translations")
        .eq("language_code", effectiveLang)
        .maybeSingle();

      if (error) {
        console.error("Supabase fetch error:", error.message);
        return;
      }
      setTranslations(data?.translations || {});
    })();
  }, [selectedLanguage, selectedLangCode]);

  useEffect(() => {
    const refText = (generatedReferral || canonicalRef || "").trim();

    const s = parseReferralToSuggestion(refText, countries, statesByCountry);
    setReferralSuggestion(s);
  }, [generatedReferral, referralCode, countries, statesByCountry]);

  useEffect(() => {
    if (!selectedLanguage) return;
    try {
      i18n?.changeLanguage?.(selectedLanguage);
    } catch {}
    if (typeof window !== "undefined") {
      localStorage.setItem("language", selectedLanguage);
    }
  }, [selectedLanguage, i18n]);

  // Fetch languages once
  useEffect(() => {
    if (fetchedLangsRef.current) return;
    fetchedLangsRef.current = true;

    (async () => {
      const { data, error } = await supabase
        .from("languages")
        .select("code, display_name")
        .eq("enabled", true);

      if (error) {
        console.error("languages fetch failed:", error.message);
        alert(tOverride("languages_load_failed") || "Failed to load languages.");
        setLanguageOptions([]);
        return;
      }
      setLanguageOptions(computeSafeLangs(data ?? []));
    })();
  }, []);

  // Defaults for address
  const defaultCountry = isAAConnector ? qrCountry : countries[0] || "India";
  const availableStates: string[] = (statesByCountry[defaultCountry] ||
    []) as string[];
  const defaultState = isAAConnector ? qrState : availableStates[0] || "";

  // Form/UI state
  type TabKey = "individual" | "business" | "b2b" | "ec" | "ic";
  const [activeTab, setActiveTab] = useState<TabKey>("individual");

   const TABS: Array<{ key: TabKey; label: string }> = [
    { key: "individual", label: "Connectors" },
    { key: "business", label: "B2C Connectors" },
    { key: "b2b", label: "B2B Connectors" },
    { key: "ec", label: "EXPORT Connections" },
    { key: "ic", label: "IMPORT Connections" },
  ];

  // prevent double-submit
  const [submitting, setSubmitting] = useState(false);


  const [connectaID, setConnectaID] = useState("");
  const [selectedContacts, setSelectedContacts] = useState<
    Array<{ name: string; tel: string }>
  >([]);
  const [fallbackNumbersText, setFallbackNumbersText] = useState("");
  const [showManual, setShowManual] = useState(false);
  const [manualNumbers, setManualNumbers] = useState<string[]>(
    ["", "", "", "", ""]
  );

  const [formData, setFormData] = useState({
    language: selectedLangCode || "",
    fullName: "",
    profession: "",
    addressLine1: "",
    addressLine2: "",
    addressLine3: "",
    city: "",
    pincode: "",
    email: "",
    recoveryMobile: initialRecoveryLocal,
    country: defaultCountry,
    state: defaultState,
    level: "AA",
  });

  // Pretty preview for Recovery
  const recoveryPreview = useMemo(() => {
    const typed = String(formData.recoveryMobile || "").trim();
    if (typed) return (prefixFromURL || "") + typed;
    if (recoveryFromURL) return recoveryFromURL;
    return "—";
  }, [formData.recoveryMobile, prefixFromURL, recoveryFromURL]);

  const languageDisplay = useMemo(() => {
    const code = selectedLanguage || selectedLangCode || "";
    if (!code) return "";
    const match = (languageOptions || []).find(
      (l: any) => canonLang(l.code) === canonLang(code)
    );
    if (match) return labelForLang(match);
    if (langLabelFromURL && langLabelFromURL !== t("select_language"))
      return langLabelFromURL;
    return codeToReadableName[code] || code.toUpperCase();
  }, [selectedLanguage, selectedLangCode, languageOptions, langLabelFromURL, t]);

  // Keep formData.language mirrored
  useEffect(() => {
    setFormData((prev) => ({
      ...prev,
      language: selectedLanguage || selectedLangCode || "",
    }));
  }, [selectedLanguage, selectedLangCode]);

  // Seed connecta ID (local preview only)
  useEffect(() => {
    if (!connectaID) setConnectaID("IN" + Date.now());
  }, [connectaID]);

  // Update state default when country changes (unless AA connector)
  useEffect(() => {
    if (isAAConnector) return;
    const newStates = statesByCountry[formData.country] || [];
    setFormData((prev) => ({
      ...prev,
      state: newStates[0] || "",
    }));
  }, [formData.country, statesByCountry, isAAConnector]);

  // Generic change handler (AA lock + child-level enforcement + phone normalize)
  const handleChange = (e: any) => {
    const { name, value } = e.target;

    if (isAAConnector && (name === "country" || name === "state")) return;

    setFormData((prev: any) => {
      const next: any = { ...prev };

      if (name === "mobile" || name === "recoveryMobile") {
        next[name] = normalizePhone(value);
      } else {
        next[name] = value;
      }

      const childFlowHC = Boolean(canonicalRef);
let parentLvlHC = extractParentLevelFromRef(canonicalRef || "") || "AA";


      if (childFlowHC) {
        if (name === "level") return prev;
        next.level = nextAlphaPair(
          /^[A-Z]{2}$/.test(parentLvlHC) ? parentLvlHC : "AA"
        );
      }

      return next;
    });
  };

  // ---- Invite helpers ----
  function generateInviteLink(code: string) {
    const origin = typeof window !== "undefined" ? window.location.origin : "";
    const link = `${origin}${invitePath}?ref=${encodeURIComponent(code)}`;
    setInviteLink(link);
  }

  async function openContacts() {
    const navAny: any = navigator as any;
    if (!navAny?.contacts?.select) {
      alert(tOverride("Contact picker not supported on this device/browser."));
      return;
    }
  }

  function parseManualNumbers(text: string): Array<{ name: string; tel: string }> {
    const raw = String(text || "")
      .split(/[,\s;]+/)
      .map((s) => s.trim())
      .filter(Boolean)
      .slice(0, 5);

    const out: Array<{ name: string; tel: string }> = [];
    raw.forEach((p, idx) => {
      let tel = p;
      if (!tel.startsWith("+") && prefixFromURL) tel = `${prefixFromURL}${tel}`;
      tel = normalizePhone(tel);
      out.push({ name: `${tOverride("Contact")} ${idx + 1}`, tel });
    });
    return out;
  }

  function applyManualNumbers() {
    const out: Array<{ name: string; tel: string }> = [];
    manualNumbers.forEach((raw, idx) => {
      const trimmed = String(raw || "").trim();
      if (!trimmed) return;
      let tel = trimmed;
      if (!tel.startsWith("+") && prefixFromURL) tel = `${prefixFromURL}${tel}`;
      tel = normalizePhone(tel);
      out.push({ name: `${tOverride("Contact")} ${idx + 1}`, tel });
    });
    setSelectedContacts(out.slice(0, 5));
  }

  function waShare(contact?: { name: string; tel: string }) {
    const text =
      "Here is my Connecta referral code: " +
      generatedReferral +
      "\nLink: " +
      inviteLink;
    const digits = (contact?.tel || "").replace(/\D/g, "");
    const to = digits ? "/" + digits : "";
    const url = "https://wa.me" + to + "?text=" + encodeURIComponent(text);
    if (typeof window !== "undefined") window.open(url, "_blank");
  }

  async function copyReferral() {
    try {
      await navigator.clipboard.writeText(String(generatedReferral));
      alert("Referral code copied!");
    } catch {}
  }

  const handleSubmit = async () => {
    console.log(
      "[sanity] typeof fetchParentLevelByReferral =",
      typeof fetchParentLevelByReferral
    );
    try {
      const msg = (key: string, fallback: string) => tOverride(key) || fallback;

      // Required basics
      if (!formData.country) {
        alert(msg("select_country", "Please select country."));
        return;
      }

      if (isAAConnector) {
        if (!formData.state) {
          alert(msg("select_state", "Please select state."));
          return;
        }
      } else {
        const statesForCountry = statesByCountry[formData.country] || [];
        if (statesForCountry.length > 0 && !formData.state) {
          alert(msg("select_state", "Please select state."));
          return;
        }
      }

      if (!formData.fullName?.trim()) {
        alert(msg("full_name_required", "Please enter your full name."));
        return;
      }

      if (!formData.profession?.trim()) {
        alert(msg("profession_required", "Please fill profession."));
        return;
      }

      if (!formData.addressLine1?.trim()) {
        alert(msg("address_line1_required", "Please fill Address Line - 1."));
        return;
      }

      if (!formData.city?.trim()) {
        alert(msg("city_required", "Please fill city."));
        return;
      }

      if (!formData.pincode?.trim()) {
        alert(msg("pincode_required", "Please enter pincode."));
        return;
      }

      const isPincodeValid = await validatePincode(
        formData.country,
        formData.pincode
      );
      if (!isPincodeValid) {
        alert(`Invalid pincode format for ${formData.country}`);
        return;
      }

      if (!mobileNumberFromURL) {
        console.error("mobileNumberFromURL is missing.");
        alert("Mobile number is missing in URL.");
        return;
      }

      if (!mobileNumberFromURL.startsWith("+")) {
        alert("Mobile number must start with country code prefix (+).");
        return;
      }

      // Child-level enforcement before insert
      {
        const childFlow = Boolean(referralCode);

        async function parentLevelFromReferral(ref: string): Promise<string> {
          try {
            const lvl = await fetchParentLevelByReferral(ref);
            const up = String(lvl || "").toUpperCase();
            return /^[A-Z]{2}$/.test(up) ? up : "AA";
          } catch {
            return "AA";
          }
        }

        if (childFlow) {
          const parentLvl = await parentLevelFromReferral(canonicalRef);
          (formData as any).level = nextAlphaPair(parentLvl);
        } else {
          const cur = String((formData as any)?.level || "").toUpperCase();
          (formData as any).level = /^[A-Z]{2}$/.test(cur) ? cur : "AA";
        }
      }

      // Build + validate numbers
      const connectorE164 = normalizePhone(mobileNumberFromURL);
      const typedRecoveryE164 = normalizePhone(
        (prefixFromURL || "") + (formData.recoveryMobile || "")
      );
      const recoveryDigits = (formData.recoveryMobile || "").replace(/\D/g, "");
      const hasRecovery = recoveryDigits.length >= 8;
      if (!hasRecovery) {
        alert("Enter a valid recovery mobile number.");
        return;
      }
      if (typedRecoveryE164 === connectorE164) {
        alert("Recovery mobile must be different from the primary mobile.");
        return;
      }
      const recoveryE164 = typedRecoveryE164;

      // AA referral validation (if provided)
     if (canonicalRef) {
        try {
         await resolveAAParentOrThrow(canonicalRef, formData.country, formData.state);
        } catch (e: any) {
          const mm = String(e?.message || "");
          if (mm !== "AA code not found") {
            alert(mm || "Invalid AA referral for the selected region.");
            return;
          }
        }
      }

      // Duplicate check
      const lookupE164 =
        dupSourceParam === "typed" ? typedRecoveryE164 : connectorE164;

      let exists = false;
      try {
        const { data: existsData, error: existsErr } = await supabase.rpc(
          "connector_exists_normalized",
          { p_mobile: lookupE164 }
        );

        if (existsErr) {
          console.warn(
            "[dup-check] RPC failed, falling back to count:",
            existsErr.message
          );
          // Try OR across columns
          let countResp = await supabase
            .from("connectors")
            .select("id", { count: "exact", head: true })
            .or(`mobile_number.eq.${lookupE164},mobile_e164.eq.${lookupE164}`);

          if (countResp.error) {
            // Fallback to single column
            countResp = await supabase
              .from("connectors")
              .select("id", { count: "exact", head: true })
              .eq("mobile_number", lookupE164);
          }

          if (countResp.error) throw countResp.error;
          exists = (countResp.count ?? 0) > 0;
        } else {
          exists = !!existsData;
        }
      } catch (e: any) {
        console.error("dup-check error:", e?.message || e);
        alert("Error validating mobile number.");
        return;
      }

      if (!skipDupCheck) {
        console.log(
          "[dup-check] source:",
          dupSourceParam,
          "search:",
          lookupE164,
          "exists:",
          exists
        );

        if (exists) {
          // Fetch existing and redirect with global_connecta_id
          const { data: existing, error: exErr } = await fetchExistingByMobile(
            connectorE164
          );

          if (exErr || !existing) {
            console.error(
              "[dup-check] existing fetch failed:",
              exErr?.message
            );
            alert(
              "This mobile is already registered and we could not fetch details."
            );
            return;
          }

          const refCode =
            existing.referralCode ?? existing.referral_code ?? "";
          if (!refCode) {
            alert(
              "This mobile is already registered but has no referral code yet. Please contact support."
            );
            return;
          }

          const params = new URLSearchParams({
            ref: refCode,
            country: existing.country || formData.country || "",
            state: existing.state || formData.state || "",
            mobile: mobileNumberFromURL || "",
            recovery: formData.recoveryMobile
              ? `${prefixFromURL || ""}${formData.recoveryMobile}`
              : "",
            prefix: prefixFromURL || "",
            connectaId: existing.global_connecta_id || "", // single source of truth
          });

          const finalUrl = `/post-join?${params.toString()}`;
          console.log("[navigate] (dup-existing) →", finalUrl);
          router.replace(finalUrl);
          return; // stop here: no insert, no RPC
        }
      } else {
        console.log("[dup-check] SKIPPED via query/env for", lookupE164);
      }

      // Optional email check
      if (formData.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
        alert("Invalid email address.");
        return;
      }
      if (hasRecovery && /\s|-/.test(formData.recoveryMobile)) {
        alert("Recovery mobile number should not contain spaces or dashes.");
        return;
      }
      if (
        hasRecovery &&
        !/^\+?[0-9]{8,15}$/.test((prefixFromURL || "") + formData.recoveryMobile)
      ) {
        alert("Invalid recovery mobile number.");
        return;
      }
      // ---- Atomic: mint IDs on server (ensure only) ----
      let parentRefForRPC: string | null = null;
      if (referralCode) {
        try {
          await resolveAAParentOrThrow(
            referralCode,
            formData.country,
            formData.state
          );
          parentRefForRPC = null; // AA root flow
        } catch (e: any) {
          const m = String(e?.message || "");
          if (m === "AA code not found") {
            parentRefForRPC = canonicalRef; // connector referral
          } else {
            alert(m || "Invalid AA referral for the selected region.");
            return;
          }
        }
      }

      const languageToUse =
        (
          selectedLanguage ||
          selectedLangCode ||
          (typeof window !== "undefined"
            ? localStorage.getItem("language") || ""
            : "") ||
          i18n?.language ||
          "en"
        )
          .toLowerCase()
          .replace("_", "-");

      const pRecovery = recoveryE164 ?? connectorE164;

     // build & sanitize payload (Step 7 hygiene)
const p_payload_raw = {
  language: languageToUse,
  connector_type: "individual",
  addressLine1: formData.addressLine1 || "",
  addressLine2: formData.addressLine2 || "",
  addressLine3: formData.addressLine3 || "",
  city: formData.city || "",
  pincode: formData.pincode || "",
  email: normalizeEmail(formData.email || ""),
  // if your individual form has these fields, they’ll be normalized; if not, they stay empty
  upi_id: normalizeUpi((formData as any).upi_id || ""),
  links: {
    website: withHttps(((formData as any).website || "") as string),
    facebook: ((formData as any).facebook || "") as string,
    instagram: ((formData as any).instagram || "") as string,
    ytShorts: ((formData as any).ytShorts || "") as string,
    youtube: ((formData as any).youtube || "") as string,
    other: ((formData as any).other || "") as string,
  },
  // individuals typically don’t send products; if present, strip URL-y descriptions
  products: sanitizeProducts((((formData as any).products || []) as any[])),
};

const p_extra_norm = {
  suffix: (formData.fullName || "").slice(0, 10),
  short_name: deriveShortName(formData.fullName || "", (undefined as any)),
};

const ensurePayload = {
  p_country: formData.country,
  p_state: formData.state,
  p_parent_ref: parentRefForRPC,
  p_mobile: connectorE164,
  p_fullname: formData.fullName || "",
  p_email: normalizeEmail(formData.email || ""),
  p_extra: p_extra_norm,
  p_recovery_e164: pRecovery,
  p_payload: p_payload_raw,
};


      setSubmitting(true);
     type EnsureRow = {
  referral_code?: string;
  referralCode?: string;
  country?: string;
  state?: string;
  global_connecta_id?: string;
};

const resp = await supabase
  .rpc("ensure_connector_by_mobile_normalized", ensurePayload)
  .single();

const rpcErr = resp.error;
const row = (resp.data ?? {}) as EnsureRow; // ← type the row explicitly


      setSubmitting(false);

      if (rpcErr) {
        if (rpcErr.code === "23502") {
          alert("Recovery mobile is required.");
          return;
        }
        if (rpcErr.code === "23514") {
          alert("Recovery mobile must be different from the primary mobile.");
          return;
        }
        console.error("[ensure RPC error]", rpcErr);
        alert(
          (tOverride("supabase_insert_error") || "supabase_insert_error") +
            ": " +
            (rpcErr.message || "")
        );
        return;
      }

      const serverReferralCode = String(
        row?.referral_code ?? row?.referralCode ?? ""
      );
      const serverCountry = String(row?.country ?? formData.country ?? "");
      const serverState = String(row?.state ?? formData.state ?? "");

      if (!serverReferralCode) {
        alert("Could not get referral code from server.");
        return;
      }

      // Fetch global_connecta_id (single source of truth) — optional
      let globalId = "";
      try {
        const { data: gRow } = await supabase
          .from("connectors")
          .select("global_connecta_id")
          .eq("referralCode", serverReferralCode)
          .maybeSingle();
        globalId = gRow?.global_connecta_id || "";
      } catch (e) {
        console.warn("[post-ensure] global_connecta_id fetch failed:", (e as any)?.message || e);
      }

      const params = new URLSearchParams({
        ref: serverReferralCode,
        country: serverCountry,
        state: serverState,
        mobile: mobileNumberFromURL || "",
        recovery: formData.recoveryMobile
          ? `${prefixFromURL || ""}${formData.recoveryMobile}`
          : "",
        prefix: prefixFromURL || "",
        connectaId: globalId || "",
      });

      const nextUrl = `/post-join?${params.toString()}`;
      console.log("[navigate] →", nextUrl);
      router.replace(nextUrl);

      return;
    } catch (err: any) {
      const msg = err?.message || "Unknown error";
      const stack = err?.stack || "No stack trace";
      console.error("Unexpected error details:", {
        message: msg,
        stack,
        full: err,
      });
      alert(tOverride("unexpected_error") + ": " + msg);
    }
  };

  return (
    <div className="min-h-screen bg-white flex flex-col items-center p-4">
      <h1 className="text-2xl font-bold text-blue-700 mb-4">
        {tOverride("Connecta Onboarding")}
      </h1>

      {/* Dev banner */}
      {process.env.NODE_ENV !== "production" &&
        (searchParams?.get("debug") ?? "") === "1" && (
          <div className="mb-2 text-xs text-gray-600">
            {tOverride("Validating connector mobile (from URL):")}{" "}
            <span className="font-mono" suppressHydrationWarning>
              {mobileNumberFromURL}
            </span>
            <span className="ml-2">• dup source:</span>
            <span className="font-mono ml-1" suppressHydrationWarning>
              {dupSourceParam}
            </span>
          </div>
        )}

      {/* Tabs */}
      <div className="flex justify-center gap-3 mb-4">
        {TABS.map(({ key, label }) => (
          <button
            key={key}
            onClick={() => setActiveTab(key)}
            className={`px-4 py-2 rounded-md ${
              activeTab === key
                ? "bg-blue-600 text-white"
                : "bg-gray-200 text-black"
            }`}
          >
            {tOverride(label)}
          </button>
        ))}
      </div>

      <PhoneSummary
        primary={mobileNumberFromURL}
        recovery={recoveryPreview}
        className="border-blue-200 bg-blue-50 text-blue-900 mb-4"
      />

      <RegionLangSummary
        language={languageDisplay}
        country={formData.country}
        state={formData.state}
        className="border-blue-200 bg-blue-50 text-blue-900 mb-4"
      />

      {/* INDIVIDUAL TAB */}
      {activeTab === "individual" && (
        <div className="bg-gray-50 p-5 rounded-2xl shadow-lg border border-gray-200 overflow-hidden">
          {!submitted ? (
            <form className="grid grid-cols-1 gap-4">
              {/* Language */}
              <div>
                <div className="flex items-center justify-between">
                  <label className="text-sm font-semibold">
                    {tOverride("Select Language")}
                  </label>
                  <button
                    type="button"
                    onClick={() => setShowLangFilter((v) => !v)}
                    className="text-xs text-blue-600 hover:underline"
                  >
                    {showLangFilter
                      ? tOverride("Hide search")
                      : tOverride("Show search")}
                  </button>
                </div>

                {showLangFilter && (
                  <input
                    type="text"
                    value={langQuery}
                    onChange={(e) => setLangQuery(e.target.value)}
                    placeholder={tOverride("Type to filter languages…")}
                    className="border rounded-md w-full h-10 px-3 text-sm bg-white text-black"
                  />
                )}

                <select
                  id="onboarding-language"
                  value={selectedLanguage || selectedLangCode || ""}
                  onChange={(e) => {
                    const code = (e.target.value || "")
                      .toLowerCase()
                      .replace("_", "-");
                    setSelectedLanguage(code);
                  }}
                  className="border p-2 rounded-md w-full bg-white text-black focus:outline-none focus:ring-2 focus:ring-blue-500 truncate"
                >
                  {(selectedLanguage || selectedLangCode) &&
                    !(languageOptions || []).some(
                      (l: any) =>
                        canonLang(l.code) ===
                        canonLang(selectedLanguage || selectedLangCode)
                    ) &&
                    (() => {
                      const sel = canonLang(
                        selectedLanguage || selectedLangCode
                      );
                      const cc = inferCountryForCodeOrLang({ code: sel });
                      const flag = cc ? countryCodeToFlagEmoji(cc) : "";
                      const text =
                        (langLabelFromURL as string) ||
                        (codeToReadableName as any)?.[sel] ||
                        sel.toUpperCase();
                      return (
                        <option value={sel}>
                          {flag ? `${flag} ${text}` : text}
                        </option>
                      );
                    })()}

                  <option value="">{tOverride("select_language")}</option>

                  {filteredLangs.length === 0 ? (
                    <option value="" disabled>
                      {tOverride("No matches")}
                    </option>
                  ) : (
                    filteredLangs.map((l: any) => (
                      <option
                        key={l.code}
                        value={String(l.code).toLowerCase()}
                        className="truncate"
                      >
                        {labelForLang(l)}
                      </option>
                    ))
                  )}
                </select>
              </div>

              {FIELD_ORDER.map((name) => (
                <div key={name}>
                  <label className="text-sm font-semibold">
                    {tOverride(FIELD_LABELS[name])}
                  </label>
                  <input
                    name={name}
                    value={(formData as any)[name] || ""}
                    onChange={handleChange}
                    className="border p-2 rounded-md w-full"
                  />
                </div>
              ))}

              {/* Country / State */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-semibold">
                    {tOverride("Select Country")}
                  </label>
                  <select
                    name="country"
                    value={formData.country}
                    onChange={handleChange}
                    className="border p-2 rounded-md"
                    disabled={lockCountry}
                  >
                    <option value="">{tOverride("select_country")}</option>
                    {countries.map((country) => (
                      <option key={country} value={country}>
                        {country}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="text-sm font-semibold">
                    {tOverride("Select State")}
                  </label>
                  <select
                    name="state"
                    value={formData.state}
                    onChange={handleChange}
                    className="border p-2 rounded-md"
                    disabled={lockState}
                  >
                    <option value="">{tOverride("select_state")}</option>
                    {availableStates.length > 0 && (
                      <option value="All States">
                        {tOverride("all_states")}
                      </option>
                    )}
                    {availableStates.map((state: string) => (
                      <option key={state} value={state}>
                        {state}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

                           <button
                type="button"
                onClick={submitting ? undefined : handleSubmit}
                disabled={submitting}
                aria-busy={submitting ? "true" : "false"}
                className={`bg-blue-600 text-white py-2 rounded-md ${
                  submitting ? "opacity-60 cursor-not-allowed" : "hover:bg-blue-700"
                }`}
              >
                {submitting ? tOverride("Submitting…") : tOverride("Submit Details")}
              </button>

            </form>
          ) : (
            <div className="grid gap-4 text-sm text-center">
              <p className="text-green-700">
                {tOverride("submitted_successfully")}
              </p>
              <p className="font-medium">
                {tOverride("your_referral_code")}: {generatedReferral}
              </p>
              {/* Recap omitted for brevity in submitted state */}
            </div>
          )}
        </div>
      )}

      {/* BUSINESS (B2C) TAB */}
      {activeTab === "business" && (
        <div className="bg-gray-50 p-5 rounded-2xl shadow-lg border border-gray-200 text-center">
          <p className="mb-3 text-sm text-gray-700">
            B2C Connectors — ₹5,999 (waived for first year)
          </p>
          <Link
            href={buildHref("b2c")}
            className="inline-block px-4 py-2 rounded bg-blue-600 text-white hover:bg-blue-700"
          >
            Open B2C Form
          </Link>
        </div>
      )}

      {/* B2B TAB */}
      {activeTab === "b2b" && (
        <div className="bg-gray-50 p-5 rounded-2xl shadow-lg border border-gray-200 text-center">
          <p className="mb-3 text-sm text-gray-700">
            B2B Companies — ₹14,999 (waived for first year)
          </p>
          <Link
            href={buildHref("b2b")}
            className="inline-block px-4 py-2 rounded bg-blue-600 text-white hover:bg-blue-700"
          >
            Open B2B Form
          </Link>
        </div>
      )}

      {/* IMPORT TAB */}
      {activeTab === "ic" && (
        <div className="bg-gray-50 p-5 rounded-2xl shadow-lg border border-gray-200 text-center">
          <p className="mb-3 text-sm text-gray-700">
            Import Connections — USD 599 (waived for first year)
          </p>
          <Link
            href={buildHref("import")}
            className="inline-block px-4 py-2 rounded bg-blue-600 text-white hover:bg-blue-700"
          >
            Open Import Form
          </Link>
        </div>
      )}

      {/* EXPORT TAB */}
      {activeTab === "ec" && (
        <div className="bg-gray-50 p-5 rounded-2xl shadow-lg border border-gray-200 text-center">
          <p className="mb-3 text-sm text-gray-700">
            Export Connections — USD 599 (waived for first year)
          </p>
          <Link
            href={buildHref("export")}
            className="inline-block px-4 py-2 rounded bg-blue-600 text-white hover:bg-blue-700"
          >
            Open Export Form
          </Link>
        </div>
      )}
    </div>
  );
}
