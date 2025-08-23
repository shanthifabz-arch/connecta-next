"use client";

import { useSearchParams } from "next/navigation";
import { useState, useEffect, useRef, useMemo } from "react";
import { useCountryStateOptions } from "@/hooks/useCountryStateOptions";
import "@/lib/i18n";
import { useTranslation } from "react-i18next";
import B2CForm from "@/components/forms/B2CForm";
import B2BForm from "@/components/forms/B2BForm";
import { validatePincode } from "@/utils/pincode";
import { supabase } from "@/lib/supabaseClient";

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
  Bangladesh: 10, // adjust if your BN rule differs
};

// Build a friendly option label, e.g. "Bangla (বাংলা) — BN-BD"
function labelForLang(l: any) {
  const name = String(l?.display_name || l?.label || l?.code || "").trim();
  const code = String(l?.code || "").trim();
  return code ? `${name} — ${code.toUpperCase()}` : name;
}
// Canonicalize all language codes to the same shape: "xx" or "xx-yy"
const canonLang = (code: string) =>
  String(code || "").trim().toLowerCase().replace(/_/g, "-");

// Human label fallback for base codes (expand as needed)
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
  return String.fromCodePoint(...code.split("").map(c => BASE + (c.charCodeAt(0) - 65)));
}

// Try to infer country from a language object or a raw code string
function inferCountryForCodeOrLang(l: any): string | null {
  // explicit country field wins
  const direct = l?.country_code || l?.country || "";
  if (typeof direct === "string" && /^[A-Za-z]{2}$/.test(direct)) return direct.toUpperCase();

  // derive from code like "bn-bd"
  const code = canonLang(l?.code || l || "");
  const parts = code.split("-");
  if (parts[1] && /^[a-z]{2}$/i.test(parts[1])) return parts[1].toUpperCase();

  // base-language heuristic
  const base = parts[0];
  const map: Record<string, string> = { id: "ID", bn: "BD", ta: "IN", hi: "IN", ur: "PK" };
  return map[base] || null;
}


// Single source of truth for language label.
// For now: always languages.display_name. If missing, fall back to code.
const uniformLabel = (l: any) =>
  String(l?.display_name || l?.label || l?.code || "")
    .toString()
    .trim() || (l?.code ? l.code.toUpperCase() : "");



// Return local-digit count from a full E.164-like string using the known prefix
function localDigitsCount(e164: string, prefix: string) {
  const cc = String(prefix || "").replace(/\D/g, "");
  const all = String(e164 || "").replace(/\D/g, "");
  return all.startsWith(cc) ? all.slice(cc.length).length : all.length;
}

const CONNECTOR_TYPES = {
  individual: "individual",
  business: "business",
  b2b: "b2b",
} as const;

// --- compact UI helpers (sizes only) ---
const inputCls   = "border rounded-md w-full h-10 px-3 text-sm bg-white text-black";
const labelCls   = "text-xs font-semibold text-gray-800";
const cardCls    = "w-full max-w-lg bg-gray-50 p-4 rounded-xl shadow-lg border border-gray-200";

// --- Helper: parse parent level from referral (e.g. INTAAD000000002 -> AD)
function extractParentLevelFromRef(ref: string): string | null {
  const s = String(ref || "").toUpperCase();
  // ...INTA AD 000... → capture the 2-letter level after the first 4 letters
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

  // Map normalized country name -> display country
  const countryMap = new Map<string, string>();
  for (const c of countries) countryMap.set(normalize(c), c);

  // Try to find a country mentioned in the referral text
  let foundCountry: string | null = null;
  for (const [key, display] of countryMap.entries()) {
    if (key && text.includes(key)) {
      foundCountry = display;
      break;
    }
  }
  if (!foundCountry) return null;

  // Try to find a state for that country (if we have any)
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

  // If no match or no states configured, default to "ALL STATES"
  return { country: foundCountry, state: foundState ?? "All States" };
}


// —— Language helpers (non-destructive) ——
function dedupeByKey(arr: any[], key: string) {
  const seen = new Set<string>();
  const out: any[] = [];
  for (const item of arr || []) {
    const k = String(item?.[key] ?? "");
    if (!k || seen.has(k)) continue;
    seen.add(k);
    out.push(item);
  }
  return out;
}

function sortLangs(arr: any[]) {
  return [...(arr || [])].sort((a, b) =>
    String(a?.display_name || a?.label || a?.code || "").localeCompare(
      String(b?.display_name || b?.label || b?.code || "")
    )
  );
}

// ✅ Extra-robust de-dupers to remove visible repetitions
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
  // 1) normalize
  const normalized = (raw || []).map((l) => ({
    ...l,
    code: String(l?.code || "").trim(),
    display_name: String(l?.display_name || l?.label || "").trim(),
  }));
  // 2) dedupe by exact code (case/space-insensitive)
  let safe = dedupeBy(normalized, (l: any) => l.code.toLowerCase());
  // 3) dedupe by base language (strip region) + display name (e.g., bn vs bn-BD both 'Bengali')
  safe = dedupeBy(
    safe,
    (l: any) => `${l.code.toLowerCase().split("-")[0]}|${(l.display_name || "").toLowerCase()}`
  );
  // 4) final sort for nice UI
  return sortLangs(safe);
}


// --- DB helper: get parent level by referralCode (ONE source of truth) ---
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



export default function OnboardingTabs() {
  const searchParams = useSearchParams();
  const { t, i18n } = useTranslation();

  
  // ✅ i18n overrides — must be declared once, before any tOverride usage
  const [translations, setTranslations] = useState<Record<string, string>>({});
  const tOverride = (key: string) => translations[key] || t(key);
 // URL params
const referralCode     = searchParams?.get("ref")       ?? "";
const qrCountry        = searchParams?.get("country")   ?? "";
const qrState          = searchParams?.get("state")     ?? "";
const selectedLangCode = searchParams?.get("lang")      ?? "";
const langLabelFromURL    = searchParams?.get("langLabel") ?? t("select_language");
const mobileNumberFromURL = searchParams?.get("mobile") ?? "";
const prefixFromURL       = searchParams?.get("prefix") ?? countryPrefixes[qrCountry] ?? "";

// ── EXTRA URL PARAMS (normalized) ──────────────────────────────────────────────
const otpFromURL = (searchParams?.get("otp") ?? "0") === "1"; // optional

// Recovery mobile from URL:
// - initialRecoveryLocal: local digits only (to prefill the input)
// - recoveryFromURL:      full E.164 for display/preview
const recoveryMobileFromURLRaw = (searchParams?.get("recoveryMobile") ?? "").trim();


const initialRecoveryLocal = recoveryMobileFromURLRaw
  ? (recoveryMobileFromURLRaw.startsWith(prefixFromURL || "")
      ? recoveryMobileFromURLRaw.slice((prefixFromURL || "").length)
      : recoveryMobileFromURLRaw.replace(/^\+/, "")) // drop '+' if full E.164
  : "";

const recoveryFromURL = recoveryMobileFromURLRaw
  ? (recoveryMobileFromURLRaw.startsWith("+")
      ? recoveryMobileFromURLRaw
      : (prefixFromURL || "") + recoveryMobileFromURLRaw)
  : "";

// (optional) If you no longer show the language search box, remove this entirely
// const [showLangFilter, setShowLangFilter] = useState(false);


  // Invite landing path can be overridden via URL (?invitePath=/join) or env (NEXT_PUBLIC_INVITE_PATH)
  const invitePathRaw =
  searchParams?.get("invitePath") ?? process.env.NEXT_PUBLIC_INVITE_PATH ?? "/welcome";

  const invitePath = invitePathRaw?.startsWith("/") ? invitePathRaw : `/${invitePathRaw}`;

  // Dev/testing helper: add `&dup=skip` in URL or set NEXT_PUBLIC_DEV_SKIP_DUP=1 to skip duplicate check
 const skipDupCheck = ((searchParams?.get("dup") ?? "") === "skip") || process.env.NEXT_PUBLIC_DEV_SKIP_DUP === "1";


  // Which number to validate for duplicates: 'url' (default) or 'typed'
  const dupSourceParam = (
  searchParams?.get("dupSource") ??
  process.env.NEXT_PUBLIC_DUP_SOURCE ??
  (process.env.NODE_ENV !== "production" ? "typed" : "url")
).toString().toLowerCase();


  const isAAConnector = qrCountry !== "" && qrState !== "";
const [referralSuggestion, setReferralSuggestion] =
  useState<{ country: string; state: string } | null>(null);

  // Country/State options
  const { countries, statesByCountry } = useCountryStateOptions();

// Language options and selection (KEEP THIS ABOVE any effect that reads selectedLanguage)
const [languageOptions, setLanguageOptions] = useState<any[]>([]);
const [selectedLanguage, setSelectedLanguage] = useState<string>("");
const [langQuery, setLangQuery] = useState(""); // <- text used to filter the dropdown
const [showLangFilter, setShowLangFilter] = useState(false); 
const fetchedLangsRef = useRef(false);
const initLangRef = useRef(false);

// Show only options that match the query (by label or code)
const filteredLangs = useMemo(() => {
  const q = langQuery.trim().toLowerCase();
  if (!q) return languageOptions;
  return (languageOptions || []).filter((l: any) => {
    const label = (uniformLabel(l) || "").toLowerCase(); // display_name first
    const code  = String(l?.code || "").toLowerCase();
    return label.includes(q) || code.includes(q);
  });
}, [langQuery, languageOptions]);

// Needed by effects/render below
const [submitted, setSubmitted] = useState(false);
const [generatedReferral, setGeneratedReferral] = useState("");
const [inviteLink, setInviteLink] = useState("");



// One-time seed of selected language (canon: lowercase + hyphen)
useEffect(() => {
  if (initLangRef.current) return;

  const qp = canonLang(selectedLangCode || "");
  const ls = typeof window !== "undefined" ? canonLang(localStorage.getItem("language") || "") : "";
  const i18nLang = canonLang(i18n?.language || "");
  const current = qp || ls || i18nLang || "en";

  if (current) {
    setSelectedLanguage(current);
    try { i18n?.changeLanguage?.(current); } catch {}
    if (typeof window !== "undefined") localStorage.setItem("language", current);
  }

  initLangRef.current = true;
  // run once on mount
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
  const refText = (generatedReferral || referralCode || "").trim();
  const s = parseReferralToSuggestion(refText, countries, statesByCountry);
  setReferralSuggestion(s);
}, [generatedReferral, referralCode, countries, statesByCountry]);


  // Keep i18n + localStorage in sync with selectedLanguage
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
        // Friendlier duplicate handling
        const emsg = String(error?.message || "");
        const edet = String((error as any)?.details || "");
        const ecode = (error as any)?.code || "";
        const isDup = ecode === "23505" || /duplicate key|unique constraint/i.test(emsg + " " + edet);
        console.error("Supabase insert error:", { code: ecode, message: emsg, details: edet });
        if (isDup) {
          alert("This mobile number is already registered as a connector.");
          return;
        }
        alert(tOverride("supabase_insert_error") + ": " + (emsg || "Unknown error"));
      } else {
        // ✅ Strong de-duplication (by code and by base-language+name)
        const safe = computeSafeLangs(data || []);
        setLanguageOptions(safe);
      }
      })();
  }, []);

  
  
  // Defaults for address
  const defaultCountry = isAAConnector ? qrCountry : countries[0] || "India";
  const availableStates = statesByCountry[defaultCountry] || [];
  const defaultState = isAAConnector ? qrState : availableStates[0] || "";

  // Form/UI state
  const [activeTab, setActiveTab] = useState<"individual" | "business" | "b2b">(
    "individual"
  );
  const [connectaID, setConnectaID] = useState("");
  const [selectedContacts, setSelectedContacts] = useState<Array<{ name: string; tel: string }>>([]);
  const [fallbackNumbersText, setFallbackNumbersText] = useState("");
  const [showManual, setShowManual] = useState(false);
  const [manualNumbers, setManualNumbers] = useState<string[]>(["", "", "", "", ""]);

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
  recoveryMobile: initialRecoveryLocal,  // ← here
  country: defaultCountry,
  state: defaultState,
});



  // Pretty preview for Recovery: prefer typed, else URL, else a dash
const recoveryPreview = useMemo(() => {
  const typed = String(formData.recoveryMobile || "").trim();
  if (typed) return (prefixFromURL || "") + typed;
  if (recoveryFromURL) return recoveryFromURL;
  return "—";
}, [formData.recoveryMobile, prefixFromURL, recoveryFromURL]);


  // Keep formData.language mirrored with selectedLanguage (or URL code as fallback)
  useEffect(() => {
    setFormData((prev) => ({
      ...prev,
      language: selectedLanguage || selectedLangCode || "",
    }));
  }, [selectedLanguage, selectedLangCode]);

  // Seed connecta ID
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

// ========================= REPLACEMENT START =========================

// Generic change handler (AA lock + child-level enforcement + phone normalize)
const handleChange = (e: any) => {
  const { name, value } = e.target;

  // 1) AA connectors cannot change country/state
  if (isAAConnector && (name === "country" || name === "state")) return;

  setFormData((prev: any) => {
    const next: any = { ...prev };



// 2) Normalize phone fields on the fly
if (name === "mobile" || name === "recoveryMobile") {
  next[name] = normalizePhone(value);
} else {
  next[name] = value;
}

// 3) Enforce child-level rule (sync; no DB)
// Treat as child if we have a parent ref or explicit child flags
const childFlowHC =
  Boolean(referralCode);

// Resolve parent level from state; fall back to referral string (e.g. INTAAD... -> AD)
let parentLvlHC = (next.parent_level || next.parentLevel || "")
  .toString()
  .toUpperCase();
if (childFlowHC && !/^[A-Z]{2}$/.test(parentLvlHC)) {
  const fromRef = extractParentLevelFromRef(referralCode || "");
  if (fromRef) parentLvlHC = fromRef;
}

if (childFlowHC) {
  // Never allow manual edits to level for child connectors
  if (name === "level") return prev;

  // Derive correct child level (e.g., AD -> AE)
  next.level = nextAlphaPair(/^[A-Z]{2}$/.test(parentLvlHC) ? parentLvlHC : "AA");
}


    return next;
  });
};

// Next double-letter helper (AA->AB->...->AZ->BA...)
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

// Normalize phone to E.164-like
function normalizePhone(raw: string) {
  const s = String(raw || "").trim();
  let cleaned = s.replace(/[^0-9+]/g, "");
  if (cleaned.startsWith("00")) cleaned = "+" + cleaned.slice(2);
  cleaned = cleaned.replace(/(?!^)\+/g, "");
  return cleaned;
}

// ========================== REPLACEMENT END =========================

 // ---- Invite helpers (referral link + contacts + WhatsApp) ----
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

// Manual entry fallback (desktop or unsupported browsers)
function parseManualNumbers(text: string): Array<{ name: string; tel: string }> {
  const raw = String(text || "")
   .split(/[,\s;]+/).map(s => s.trim()).filter(Boolean).slice(0, 5);

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
    "Here is my Connecta referral code: " + generatedReferral +
    "\\nLink: " + inviteLink; // use \n line break
  const digits = (contact?.tel || "").replace(/\D/g, "");
  const to = digits ? "/" + digits : "";
  const url = "https://wa.me" + to + "?text=" + encodeURIComponent(text);
  if (typeof window !== "undefined") window.open(url, "_blank");
}


  async function copyReferral() {
    try {
      await navigator.clipboard.writeText(String(generatedReferral));
      alert('Referral code copied!');
    } catch {}
  }
const handleSubmit = async () => {
  console.log("[sanity] typeof fetchParentLevelByReferral =", typeof fetchParentLevelByReferral);
  try {
    // ✅ REQUIRED FIELDS (country/state carried from Welcome; language is changeable but NOT required)
    const msg = (key: string, fallback: string) => tOverride(key) || fallback;

    // Country — required (guard deep-link/broken flow)
    if (!formData.country) {
      alert(msg("select_country", "Please select country."));
      return;
    }

    // State — required if AA connector OR if chosen country has states
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

    // Language — NOT required (removed the old check)

    // Full name — Required
    if (!formData.fullName?.trim()) {
      alert(msg("full_name_required", "Please enter your full name."));
      return;
    }

    // Profession — Required
    if (!formData.profession?.trim()) {
      alert(msg("profession_required", "Please fill profession."));
      return;
    }

    // Address Line 1 — Required
    if (!formData.addressLine1?.trim()) {
      alert(msg("address_line1_required", "Please fill Address Line - 1."));
      return;
    }

    // City — Required
    if (!formData.city?.trim()) {
      alert(msg("city_required", "Please fill city."));
      return;
    }

    // Pincode — Required (format validated below)
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
    // ────────────────────────────────────────────────
// Enforce correct child level before insert (isolated scope, no name clashes)
// ────────────────────────────────────────────────
{
const __childFlow = Boolean(referralCode);

console.log("[child] gate", { referralCode, __childFlow });

// 1) Read parent level from state first
let parentLevelRaw = "";
console.log("[child] parent level (state)", { parentLevelRaw });


// Utility to finish derivation + enforce
const finish = () => {
  const parentLevel = /^[A-Z]{2}$/.test(parentLevelRaw.toUpperCase())
    ? parentLevelRaw.toUpperCase().trim()
    : "AA";
  const derived = nextAlphaPair(parentLevel);

  console.log("[child] derive", {
    parentLevelRaw,
    parentLevel,
    derived,
    beforeFormLevel: formData?.level,
  });

  if (__childFlow) {
    formData.level = derived;
    console.log("[child] final formData.level", formData.level);
  }
};
// 2) If missing/invalid, try lookup by referral (promise chain, no await)
if (!/^[A-Za-z]{2}$/.test(parentLevelRaw.toUpperCase()) && referralCode) {
  console.log("[child] parent lookup via referral…", { referralCode });

  fetchParentLevelByReferral(referralCode)
    .then((lvl) => {
      console.log("[child] lookup result", { level: lvl });
      if (lvl) parentLevelRaw = lvl; // <- set the parent level if found
    })
    .catch((e) => console.warn("[child] parent lookup threw", e))
    .finally(finish); // <- always call finish()

} else {
  finish();
}

  // read from state; if missing, fetch by referral
 let __parentLvl = "";

if (__childFlow && !/^[A-Z]{2}$/.test(__parentLvl)) {
  try {
    const fetched = await fetchParentLevelByReferral(referralCode);
    if (fetched) {
      __parentLvl = fetched;
    } else {
      console.warn("[child] parent level lookup failed (no row)");
    }
  } catch (__e) {
    console.warn("[child] parent level lookup exception:", __e);
  }
}


  const __expectedLvl = __childFlow
    ? nextAlphaPair(/^[A-Z]{2}$/.test(__parentLvl) ? __parentLvl : "AA")
    : (formData?.level?.toString().toUpperCase() || "AA");

  if (__childFlow) formData.level = __expectedLvl; // <- force AE for AD parent

  console.log("[DEBUG] parentLevelRaw:", __parentLvl);
  console.log("[DEBUG] expectedChildLevel:", __expectedLvl);
  console.log("[DEBUG] final formData.level:", formData.level);
}

// ────────────────────────────────────────────────
// Enforce/derive correct child level before insert
// ────────────────────────────────────────────────
const isChild = !!referralCode; // child flow whenever we have a parent ref

// Try to get parent level (from state or DB)
let parentLevelRaw = (
  ""
).toString().toUpperCase();

if (isChild && !/^[A-Z]{2}$/.test(parentLevelRaw)) {
  try {
    const { data: parentRow, error: parentErr } = await supabase
      .from("connectors")
      .select("level")
      .eq("referralCode", referralCode)
      .maybeSingle();
    if (!parentErr && parentRow?.level) {
      parentLevelRaw = String(parentRow.level).toUpperCase();
    } else if (parentErr) {
      console.warn("[child] parent level lookup failed:", parentErr.message);
    }
  } catch (e) {
    console.warn("[child] parent level lookup exception:", e);
  }
}

// Expected next level (e.g., AD -> AE)
const expectedChildLevel = isChild
  ? nextAlphaPair(/^[A-Z]{2}$/.test(parentLevelRaw) ? parentLevelRaw : "AA")
  : (formData?.level?.toString().toUpperCase() || "AA");

// Reflect in formData (so anything downstream sees it)
if (isChild) formData.level = expectedChildLevel;

console.log("[DEBUG] parentLevelRaw:", parentLevelRaw);
console.log("[DEBUG] expectedChildLevel:", expectedChildLevel);
console.log("[DEBUG] final formData.level:", formData.level);


    // ---- Which number to check for duplicates (dev helpers only) ----
    const connectorE164 = normalizePhone(mobileNumberFromURL);  // always the URL connector number
    const typedRecoveryE164 = normalizePhone((prefixFromURL || '') + (formData.recoveryMobile || ''));



    // treat "empty" recovery (no digits typed) as null
    const recoveryDigits = (formData.recoveryMobile || '').replace(/\D/g, '');
    const hasRecovery = recoveryDigits.length >= 8;  // only treat as present if it has real digits
    const recoveryE164 = hasRecovery ? typedRecoveryE164 : null;

    // when we *check* duplicates in dev, we can choose the source; but the
    // connector we *insert* MUST be the URL number (connectorE164)
    const lookupE164 = dupSourceParam === 'typed' ? typedRecoveryE164 : connectorE164;

    // ---- Duplicate check (same as before, but using lookupE164) ----
    let exists = false;
    try {
      const { data: existsData, error: existsErr } = await supabase
        .rpc('connector_exists_normalized', { p_mobile: lookupE164 });

      if (existsErr) {
        console.warn('[dup-check] RPC failed, falling back to count:', existsErr.message);
        const { count: mobileCount, error: countFallbackErr } = await supabase
          .from('connectors')
          .select('id', { count: 'exact', head: true })
          .eq('mobile_number', lookupE164);
        if (countFallbackErr) throw countFallbackErr;
        exists = (mobileCount ?? 0) > 0;
      } else {
        exists = !!existsData;
      }
    } catch (e: any) {
      console.error('dup-check error:', e?.message || e);
      alert('Error validating mobile number.');
      return;
    }

    if (!skipDupCheck) {
      console.log('[dup-check] source:', dupSourceParam, 'search:', lookupE164, 'exists:', exists);
      if (exists) {
        alert('This mobile number is already registered as a connector.');
        return;
      }
    } else {
      console.log('[dup-check] SKIPPED via query/env for', lookupE164);
    }

    // Optional email check (unchanged)
    if (formData.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      alert("Invalid email address.");
      return;
    }
    // BEFORE the replacement block, keep validations but guard them:
    if (hasRecovery && /\s|-/.test(formData.recoveryMobile)) {
      alert("Recovery mobile number should not contain spaces or dashes.");
      return;
    }
    if (hasRecovery && !/^\+?[0-9]{8,15}$/.test((prefixFromURL || "") + formData.recoveryMobile)) {
      alert("Invalid recovery mobile number.");
      return;
    }

// ---- Atomic: generate + insert in one RPC (ALWAYS use connectorE164 here) ----
// Use FULL two-letter level (AD->AE => 'AE')
const childBranch = isChild ? (expectedChildLevel?.toUpperCase() || null) : null;

// Final guard: normalize/force level for child flow (no async here)
{
  const __childFlow =
    Boolean(referralCode);

  if (__childFlow) {
    const __parentLvlRaw = "";
    const __base = /^[A-Z]{2}$/.test(__parentLvlRaw) ? __parentLvlRaw : "AA";
    const __derived = nextAlphaPair(__base); // e.g., AD -> AE

    if (!formData.level || !/^[A-Z]{2}$/i.test(String(formData.level))) {
      formData.level = __derived;
      console.warn("[UI] Fallback set formData.level ->", formData.level, "(parent:", __parentLvlRaw, ")");
    } else {
      formData.level = String(formData.level).toUpperCase();
    }
  }
}

// Build the exact payload ONCE, after enforcing level
const payload = {
  p_country: formData.country,
  p_state: formData.state,
  p_parent_ref: referralCode,           // parent referral from URL
  p_mobile_e164: connectorE164,         // connector’s URL number (normalized)
  p_recovery_e164: recoveryE164,        // or null
  p_shortname: formData.fullName,
 p_child_branch: referralCode ? (expectedChildLevel?.toUpperCase() || null) : null, // e.g. 'AE'
         // e.g. 'E' for AD->AE
  p_payload: {
    fullName: formData.fullName,
    language: formData.language,
    profession: formData.profession,
    addressLine1: formData.addressLine1,
    addressLine2: formData.addressLine2,
    addressLine3: formData.addressLine3,
    city: formData.city,
    pincode: formData.pincode,
    email: formData.email,
    connector_type: CONNECTOR_TYPES.individual,
  },
};

// 🔎 Log the EXACT JSON we are sending to the server
console.log("[RPC about-to-send]", JSON.stringify(payload, null, 2));
console.log("[RPC guard] level & childBranch", {
  level: String(formData.level || "").toUpperCase(),
  childBranch,
});

// Call RPC with the built payload
const { data: inserted, error: rpcErr } = await supabase.rpc(
  "generate_and_insert_connector_v1",
  payload
);


    if (rpcErr) {
      console.error("RPC error:", rpcErr);
      alert((tOverride("supabase_insert_error") || "supabase_insert_error") + ": " + (rpcErr.message || ""));
      return;
    }

    // ✅ Use the RPC output directly
    const row = Array.isArray(inserted) ? inserted[0] : inserted;
    const refCode = row?.referral_code || row?.referralCode;
    if (!refCode) {
      alert("Could not get referral code from server.");
      return;
    }
    setGeneratedReferral(refCode);
    generateInviteLink(refCode);
    setSubmitted(true);

  } catch (err: any) {
    const msg = err?.message || "Unknown error";
    const stack = err?.stack || "No stack trace";
    console.error("Unexpected error details:", { message: msg, stack, full: err });
    alert(tOverride("unexpected_error") + ": " + msg);
  }
};

  return (
  <div className="min-h-screen bg-white flex flex-col items-center p-4">
    <h1 className="text-2xl font-bold text-blue-700 mb-4">
      {tOverride("Connecta Onboarding")}
    </h1>

    {/* Dev banner (only when ?debug=1) */}
    {process.env.NODE_ENV !== "production" && (searchParams?.get("debug") ?? "") === "1" && (

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
{/* ONE SHARED WIDTH WRAPPER — tabs + phone summary + tab content */}
<div className="w-full max-w-xl mx-auto">
  {/* Top tabs (centered within the same width) */}
  <div className="flex justify-center gap-3 mb-4">
    {[
      { key: "individual", label: "Connectors" },
      { key: "business",   label: "B2C Connectors" },
      { key: "b2b",        label: "B2B Connectors" },
      { key: "ec",         label: "EXPORT Connections" },
      { key: "ic",         label: "IMPORT Connections" },
    ].map(({ key, label }) => (
      <button
        key={key}
        onClick={() => setActiveTab(key as any)}
        className={`px-4 py-2 rounded-md ${
          activeTab === key ? "bg-blue-600 text-white" : "bg-gray-200 text-black"
        }`}
      >
        {tOverride(label)}
      </button>
    ))}
  </div>

  {/* Phone summary (2 tight rows, bold numbers) */}
  <div className="rounded-md border border-blue-200 bg-blue-50 text-blue-900 px-3 py-2 leading-tight mb-4">
    <div className="flex items-center justify-between text-xs">
      <span className="font-semibold uppercase tracking-wide">Primary phone</span>
      <span className="font-mono font-bold truncate">{mobileNumberFromURL || "—"}</span>
    </div>
    <div className="flex items-center justify-between text-xs">
      <span className="font-semibold uppercase tracking-wide">Recovery phone</span>
      <span className="font-mono font-bold truncate">{recoveryPreview}</span>
    </div>
  </div>

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
                {showLangFilter ? tOverride("Hide search") : tOverride("Show search")}
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
                const code = (e.target.value || "").toLowerCase().replace("_", "-");
                setSelectedLanguage(code);
              }}
              className="border p-2 rounded-md w-full bg-white text-black focus:outline-none focus:ring-2 focus:ring-blue-500 truncate"
            >
              {(selectedLanguage || selectedLangCode) &&
  !(languageOptions || []).some(
    (l: any) => canonLang(l.code) === canonLang(selectedLanguage || selectedLangCode)
  ) && (() => {
    const sel = canonLang(selectedLanguage || selectedLangCode);
    const cc = inferCountryForCodeOrLang({ code: sel });
    const flag = cc ? countryCodeToFlagEmoji(cc) : "";
    const text = langLabelFromURL || (codeToReadableName?.[sel] ?? sel.toUpperCase());
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
                  <option key={l.code} value={String(l.code).toLowerCase()} className="truncate">
                    {labelForLang(l)}
                  </option>
                ))
              )}
            </select>
          </div>

          {/* Text fields */}
          {[
            "fullName",
            "profession",
            "addressLine1",
            "addressLine2",
            "addressLine3",
            "city",
            "pincode",
            "email",
          ].map((name) => (
            <div key={name}>
              <label className="text-sm font-semibold">
                {tOverride(
                  {
                    fullName: "Full Name",
                    profession: "Profession",
                    addressLine1: "Address Line - 1",
                    addressLine2: "Address Line - 2",
                    addressLine3: "Address Line - 3",
                    city: "City",
                    pincode: "Pincode",
                    email: "Email",
                  }[name as keyof any]
                )}
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
              <label className="text-sm font-semibold">{tOverride("Select Country")}</label>
              <select
                name="country"
                value={formData.country}
                onChange={handleChange}
                className="border p-2 rounded-md"
                disabled={isAAConnector}
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
              <label className="text-sm font-semibold">{tOverride("Select State")}</label>
              <select
                name="state"
                value={formData.state}
                onChange={handleChange}
                className="border p-2 rounded-md"
                disabled={isAAConnector}
              >
                <option value="">{tOverride("select_state")}</option>
                {availableStates.length > 0 && (
                  <option value="All States">{tOverride("all_states")}</option>
                )}
                {availableStates.map((state) => {
                  const key = typeof state === "string" ? state : state.name;
                  const val = typeof state === "string" ? state : state.name;
                  return (
                    <option key={key} value={val}>
                      {val}
                    </option>
                  );
                })}
              </select>
            </div>
          </div>

          <button
            type="button"
            onClick={handleSubmit}
            className="bg-blue-600 text-white py-2 rounded-md hover:bg-blue-700"
          >
            {tOverride("Submit Details")}
          </button>
        </form>
      ) : (
        <div className="grid gap-4 text-sm text-center">
          <p className="text-green-700">{tOverride("submitted_successfully")}</p>
          <p className="font-medium">
            {tOverride("your_referral_code")}: {generatedReferral}
          </p>

          {/* Primary & Recovery recap */}
          <div className="mx-auto w-full max-w-md mt-2">
            <div className="grid grid-cols-1 gap-2 text-left">
              <div className="rounded-lg border p-3 bg-white">
                <div className="text-xs text-gray-500">
                  {tOverride("Primary mobile (from invite)")}
                </div>
                <div className="font-mono text-sm" suppressHydrationWarning>
                  {mobileNumberFromURL}
                </div>
              </div>

              <div className="rounded-lg border p-3 bg-white">
                <div className="text-xs text-gray-500">
                  {tOverride("Recovery mobile (you entered)")}
                </div>
                <div className="font-mono text-sm" suppressHydrationWarning>
                  {formData.recoveryMobile
                    ? `${prefixFromURL || ""}${formData.recoveryMobile}`
                    : tOverride("Not provided")}
                </div>
              </div>
            </div>
          </div>

          {/* Share & contacts block */}
          <div className="mt-2 p-4 rounded-xl border bg-white text-left">
            <h3 className="text-base font-semibold mb-2">
              {tOverride("ADD YOUR CONNECTORS")}
            </h3>

            {referralSuggestion && (
              <div className="mb-3 w-full max-w-md mx-auto rounded-lg border border-blue-200 bg-blue-50 text-blue-900 p-3">
                <div className="text-sm mb-2">
                  Detected from referral:&nbsp;
                  <b>{referralSuggestion.country}</b> / <b>{referralSuggestion.state}</b>
                </div>
                <div className="flex gap-2 justify-center">
                  <button
                    type="button"
                    className="px-3 py-1 rounded bg-blue-600 text-white hover:bg-blue-700"
                    onClick={() => {
                      setFormData((prev) => ({
                        ...prev,
                        country: referralSuggestion.country,
                        state: referralSuggestion.state,
                      }));
                    }}
                  >
                    Apply
                  </button>
                  <button
                    type="button"
                    className="px-3 py-1 rounded border border-blue-300 hover:bg-blue-100"
                    onClick={() => setReferralSuggestion(null)}
                  >
                    Ignore
                  </button>
                </div>
              </div>
            )}

            <div className="mb-3">
              <button
                type="button"
                onClick={copyReferral}
                className="px-3 py-2 rounded-md bg-blue-100"
              >
                {tOverride("Copy Referral Code")}
              </button>
            </div>

            <div className="flex flex-wrap items-center gap-2 mb-3">
              {typeof navigator !== "undefined" &&
                (navigator as any)?.contacts?.select && (
                  <button
                    type="button"
                    onClick={openContacts}
                    className="px-3 py-2 rounded-md bg-gray-200"
                  >
                    {tOverride("CLICK HERE TO OPEN CONTACTS")}
                  </button>
                )}

              <button
                type="button"
                onClick={() => waShare()}
                className="px-3 py-2 rounded-md bg-green-200"
              >
                {tOverride("SEND YOUR REFERRAL CODE by whatsApp")}
              </button>

              <button
                type="button"
                onClick={() => setShowManual((v) => !v)}
                className="px-3 py-2 rounded-md bg-gray-100"
              >
                {tOverride("Hide manual entry")}
              </button>
            </div>

            {(!(typeof navigator !== "undefined" && (navigator as any)?.contacts?.select) ||
              showManual) && (
              <div className="mb-3">
                <label className="text-sm font-semibold mb-1 block">
                  {tOverride("Paste up to 5 numbers (comma or newline separated)")}
                </label>
                <textarea
                  value={fallbackNumbersText}
                  onChange={(e) => setFallbackNumbersText(e.target.value)}
                  placeholder={tOverride("Ex: 9876543210, 9876543211 or each on new line")}
                  className="w-full border rounded-md p-2 h-24"
                />
                <div className="mt-2 flex gap-2">
                  <button
                    type="button"
                    onClick={applyManualNumbers}
                    className="px-3 py-2 rounded-md bg-gray-200"
                  >
                    {tOverride("Add to contacts list")}
                  </button>
                </div>
              </div>
            )}
            <div className="text-xs text-gray-600 mb-2">
              <span className="font-semibold">{tOverride("SELECT UP TO 5 CONTACTS")}</span>
            </div>
            {selectedContacts.length > 0 && (
              <ul className="space-y-2">
                {selectedContacts.map((c, i) => (
                  <li key={i} className="flex items-center justify-between bg-gray-50 rounded-md p-2">
                    <span className="text-sm">
                      {c.name} — {c.tel}
                    </span>
                    <button
                      type="button"
                      onClick={() => waShare(c)}
                      className="px-2 py-1 text-sm rounded bg-green-500 text-white"
                    >
                      WhatsApp
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </div>
      )}
    </div>
  )}

  {/* BUSINESS TAB */}
  {activeTab === "business" && (
    <div className="bg-gray-50 p-5 rounded-2xl shadow-lg border border-gray-200">
      <B2CForm />
    </div>
  )}

  {/* B2B TAB */}
  {activeTab === "b2b" && (
    <div className="bg-gray-50 p-5 rounded-2xl shadow-lg border border-gray-200">
      <B2BForm />
    </div>
  )}
</div>
</div>
);
}
