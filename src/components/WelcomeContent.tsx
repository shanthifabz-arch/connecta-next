"use client";

import { useState, useEffect, useRef } from "react";
import { useTranslation } from "react-i18next";
import { useRouter } from "next/navigation";
import { useLanguageOptions } from "@/hooks/useLanguageOptions";
import { useCountryStateOptions } from "@/hooks/useCountryStateOptions";
import "@/lib/i18n";
import { supabase } from "@/lib/supabaseClient";

// --- AA seed detector (ONLY for aa_connectors validation) ---
// Accepts:
//   "India_M253540"
//   "India_Tamilnadu_M253540"
//   "India_Tamil Nadu_M253540"
// Allows underscores or spaces between tokens. DOES NOT match INTAAA/INTAAB/etc.
const AA_SEED_PATTERN = /^[A-Za-z]+(?:[_\s][A-Za-z]+)*(?:[_\s]M\d+)$/i;
const isAASeed = (code: string) => AA_SEED_PATTERN.test((code || "").trim());

// --- Helper: normalize old short serials: INTAA13 -> INTAA000000013 ---
function padINTA(ref: string): string {
  const re = /(.*_INTA[A-Z]{2})(\d+)(.*)$/i;
  const m = (ref || "").trim().match(re);
  if (!m) return ref;
  const [_, head, digits, tail] = m;
  return `${head}${digits.padStart(9, "0")}${tail}`;
}


// === Language helpers (SINGLE definition — do not duplicate) ===
type LangItem = {
  language_iso_code?: string | null;
  language_code?: string | null;
  code?: string | null;
  display_name?: string | null;
  label_native?: string | null;
  emoji_flag?: string | null;
};

// Built-in minimal English fallback (used only if DB has neither lang nor 'en')
const FALLBACK_EN: Record<string, any> = {
  welcome_to: "WELCOME TO",
  capitalize_your_contacts: "Capitalize your contacts",
  enter_referral_placeholder: "Enter referral code (e.g., India_Tamilnadu_M253540)",
  select_language: "Select language",
  language_label: "Select Language",
  enter_mobile_placeholder: "Enter mobile number",
  enter_recovery_mobile_placeholder: "Enter recovery mobile number",
  select_country: "Select Country",
  select_state: "Select State",
  join_connecta_community: "Join Connecta Community",
  alert: { accept_terms: "Please accept the terms and conditions." },
};


// Canonicalize codes like "en_US" → "en-us"
const normalizeLang = (s?: string | null) =>
  (s ?? "en").toLowerCase().replace(/_/g, "-");

// Minimal readable-name fallback for base codes (expand as needed)
const codeToReadableName: Record<string, string> = {
  en: "English",
  ta: "Tamil",
};
// One canonical label for the UI & logic
const ALL_STATES = "All States";

// Prefer ISO (e.g., "ta"), then fall back to language_code, then code
const langCodeFrom = (lang: LangItem | null | undefined): string =>
  normalizeLang(
    String(lang?.language_iso_code ?? lang?.language_code ?? lang?.code ?? "")
  ).trim();

// Preserve a leading flag emoji; otherwise strip leading symbols and squash spaces
const cleanName = (s?: string | null): string => {
  const str = (s ?? "").replace(/\s+/g, " ").trim();
  // Preserve a leading country flag (pair of regional indicators)
  if (/^[\u{1F1E6}-\u{1F1FF}]{2}/u.test(str)) return str;
  return str.replace(/^[^\p{L}\p{N}]+/u, "");
};

// Convert ISO country code ("IN") → "🇮🇳"
function countryCodeToFlagEmoji(cc?: string | null) {
  const code = String(cc || "").toUpperCase();
  if (!/^[A-Z]{2}$/.test(code)) return "";
  const BASE = 0x1F1E6;
  return String.fromCodePoint(...code.split("").map(c => BASE + (c.charCodeAt(0) - 65)));
}

// Infer a country for a language option to show a flag
function inferCountryForLangItem(lang: LangItem): string | null {
  // Prefer explicit country fields if present
  const direct = (lang as any)?.country_code || (lang as any)?.country || "";
  if (typeof direct === "string" && /^[A-Za-z]{2}$/.test(direct)) return direct.toUpperCase();

  // Next try region from code, e.g., "bn-bd" → "BD"
  const code = langCodeFrom(lang); // e.g., "bn-bd" or "ta"
  const parts = code.split("-");
  if (parts[1] && /^[a-z]{2}$/i.test(parts[1])) return parts[1].toUpperCase();

  // Base-language heuristic map
  const base = parts[0];
  const baseMap: Record<string, string> = {
    id: "ID", // Indonesian → 🇮🇩
    bn: "BD", // Bengali (Bangladesh) → 🇧🇩
    ta: "IN", // Tamil (default) → 🇮🇳
    hi: "IN",
    ur: "PK",
    kn: "IN",
    ml: "IN",
    te: "IN",
    pa: "IN",
    mr: "IN",
    gu: "IN",
  };
  return baseMap[base] || null;
}

// Build a friendly label that starts with the readable name, with a flag prefix and code suffix
const buildLangLabel = (lang: LangItem): { code: string; label: string } => {
  const code = langCodeFrom(lang); // "ta", "bn-bd", etc.
  const nameA = cleanName(lang.display_name); // e.g., "Tamil (தமிழ்)"
  const nameB = cleanName(lang.label_native); // e.g., "தமிழ்"

  let name =
    nameA ||
    nameB ||
    codeToReadableName[code] ||                // fallback to human name for full code
    codeToReadableName[code.split("-")[0]] ||  // fallback to base part (e.g., "bn" for "bn-bd")
    code.toUpperCase();

  if (
    nameA &&
    nameB &&
    nameA.toLowerCase() !== nameB.toLowerCase() &&
    !nameA.toLowerCase().includes(nameB.toLowerCase()) &&
    !nameB.toLowerCase().includes(nameA.toLowerCase())
  ) {
    name = `${nameA} / ${nameB}`;
  }

  const cc = inferCountryForLangItem(lang);
  const flag = cc ? countryCodeToFlagEmoji(cc) : "";

  // Avoid double-flag if the label already starts with a flag
  const alreadyHasFlag = /^[\u{1F1E6}-\u{1F1FF}]{2}/u.test(name);
  const prefix = !alreadyHasFlag && flag ? flag + " " : "";

  // Keep code at the END so browser type-to-select matches on the name.
  const label = `${prefix}${name}${code ? ` — ${code.toUpperCase()}` : ""}`;
  return { code, label };
};


// --- Helper: infer country/state from the referral code ---
const normalizeRef = (s: string) =>
  (s ?? "")
    .toLowerCase()
    .replace(/[_-]+/g, " ")
    .replace(/[^\p{L}\p{N}\s]/gu, " ")
    .replace(/\s+/g, " ")
    .trim();

function parseReferralToSuggestion(
  ref: string,
  countries: string[],
  statesByCountry: Record<string, any[]>
): { country: string; state: string } | null {
  const text = normalizeRef(ref);              // e.g. "india tamilnadu m253540"
  if (!text) return null;

  const textNoSpace = text.replace(/\s+/g, ""); // e.g. "indiatamilnadum253540"

  // Map normalized country name -> display country
  const countryMap = new Map<string, string>();
  for (const c of countries) countryMap.set(normalizeRef(c), c);

  // Find a country mentioned in the referral text
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

  for (const raw of states) {
    const stateName =
      typeof raw === "string" ? raw : (raw as any)?.name ?? String(raw);

    // "Tamil Nadu" -> "tamil nadu", and space-insensitive "tamilnadu"
    const key = normalizeRef(stateName);
    const keyNoSpace = key.replace(/\s+/g, "");

    // Match either with spaces OR without spaces
    if ((key && text.includes(key)) || (keyNoSpace && textNoSpace.includes(keyNoSpace))) {
      foundState = stateName; // keep proper display casing from list
      break;
    }
  }

  // If no match or no states configured, default to "ALL STATES"
 return { country: foundCountry, state: foundState ?? ALL_STATES };
}

// --- Helper: call /api/validate-referral-mobile and return a uniform result ---
// --- Helper: call /api/validate-referral-mobile and return a uniform result ---
async function validateReferralAndMobileAPI(
  referralCode: string,
  mobile: string,
  type: "aa" | "child" | "auto",
  country?: string | null,
  state?: string | null,
  opts?: { signal?: AbortSignal }
): Promise<{
  valid: boolean;
  error?: string | null;
  registeredId?: string | number | null;
  reason?: string;
}> {
  try {
    console.log("[FE] Sending:", { referralCode, mobile, type, country, state });

    const res = await fetch("/api/validate-referral-mobile", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        referralCode,
        mobile,
        type,
        country: country ?? null,
        state: state ?? null,
      }),
      signal: opts?.signal, // allow abort from caller
    });

    // Try to parse JSON, but don't crash if server returns empty body
    let data: any = null;
    try {
      data = await res.json();
    } catch {
      data = null;
    }
    console.log("[FE] Received response:", data);

    // 409 shortcut for duplicate mobile
    if (res.status === 409 && data?.code === "MOBILE_EXISTS") {
      return {
        valid: false,
        error: data?.message || data?.error || "Mobile number already registered",
        registeredId:
          data?.registeredId ??
          data?.registeredWith?.referralCode ??
          data?.registeredWith?.referral_code ??
          null,
        reason: "MOBILE_EXISTS",
      };
    }

    // Non-OK HTTP -> error
    if (!res.ok) {
      return {
        valid: false,
        error: data?.error || data?.message || `HTTP_${res.status}`,
        registeredId: data?.registeredId ?? null,
        reason: data?.code || "VALIDATION_ERROR",
      };
    }

    // OK HTTP: respect payload semantics
    const codeUpper = String(data?.code ?? "").toUpperCase();
    const hasValid = typeof data?.valid === "boolean";
    const isSuccess = (hasValid && data.valid === true) || codeUpper === "OK";

    if (isSuccess) {
      return {
        valid: true,
        error: null,
        registeredId: data?.registeredId ?? null,
        reason: data?.code || "OK",
      };
    }

    // HTTP 200 but business-level failure (your screenshot case)
    return {
      valid: false,
      error: data?.error || data?.message || "Validation failed",
      registeredId: data?.registeredId ?? null,
      reason: data?.code || "VALIDATION_ERROR",
    };
  } catch (err: any) {
    if (err?.name === "AbortError") {
      // Neutral result so caller can silently ignore
      return { valid: false, error: "aborted", registeredId: null, reason: "ABORTED" };
    }
    console.error("Validation error:", err);
    return {
      valid: false,
      error: "Unable to connect to server",
      registeredId: null,
      reason: "NETWORK",
    };
  }
}


const countryDialingCodes: Record<string, string> = {
  Afghanistan: "+93",
  Albania: "+355",
  Algeria: "+213",
  "American Samoa": "+1-684",
  Andorra: "+376",
  Angola: "+244",
  Anguilla: "+1-264",
  "Antigua and Barbuda": "+1-268",
  Argentina: "+54",
  Armenia: "+374",
  Aruba: "+297",
  Australia: "+61",
  Austria: "+43",
  Azerbaijan: "+994",
  Bahamas: "+1-242",
  Bahrain: "+973",
  Bangladesh: "+880",
  Barbados: "+1-246",
  Belarus: "+375",
  Belgium: "+32",
  Belize: "+501",
  Benin: "+229",
  Bermuda: "+1-441",
  Bhutan: "+975",
  Bolivia: "+591",
  "Bosnia and Herzegovina": "+387",
  Botswana: "+267",
  Brazil: "+55",
  "British Virgin Islands": "+1-284",
  Brunei: "+673",
  Bulgaria: "+359",
  "Burkina Faso": "+226",
  Burundi: "+257",
  "Cabo Verde": "+238",
  Cambodia: "+855",
  Cameroon: "+237",
  Canada: "+1",
  "Caribbean Netherlands": "+599",
  "Cayman Islands": "+1-345",
  "Central African Republic": "+236",
  Chad: "+235",
  Chile: "+56",
  China: "+86",
  Colombia: "+57",
  Comoros: "+269",
  Congo: "+242",
  "Cook Islands": "+682",
  "Costa Rica": "+506",
  "Côte d'Ivoire": "+225",
  Croatia: "+385",
  Cuba: "+53",
  Curaçao: "+599",
  Cyprus: "+357",
  "Czech Republic": "+420",
  Denmark: "+45",
  Djibouti: "+253",
  Dominica: "+1-767",
  "Dominican Republic": "+1-809",
  "DR Congo": "+243",
  Ecuador: "+593",
  Egypt: "+20",
  "El Salvador": "+503",
  "Equatorial Guinea": "+240",
  Eritrea: "+291",
  Estonia: "+372",
  Eswatini: "+268",
  Ethiopia: "+251",
  "Faeroe Islands": "+298",
  "Falkland Islands": "+500",
  Fiji: "+679",
  Finland: "+358",
  France: "+33",
  "French Guiana": "+594",
  "French Polynesia": "+689",
  Gabon: "+241",
  Gambia: "+220",
  Georgia: "+995",
  Germany: "+49",
  Ghana: "+233",
  Gibraltar: "+350",
  Greece: "+30",
  Greenland: "+299",
  Grenada: "+1-473",
  Guadeloupe: "+590",
  Guam: "+1-671",
  Guatemala: "+502",
  Guinea: "+224",
  "Guinea-Bissau": "+245",
  Guyana: "+592",
  Haiti: "+509",
  Honduras: "+504",
  Hungary: "+36",
  Iceland: "+354",
  India: "+91",
  Indonesia: "+62",
  Iran: "+98",
  Iraq: "+964",
  Ireland: "+353",
  "Isle of Man": "+44-1624",
  Israel: "+972",
  Italy: "+39",
  Jamaica: "+1-876",
  Japan: "+81",
  Jordan: "+962",
  Kazakhstan: "+7",
  Kenya: "+254",
  Kiribati: "+686",
  Kuwait: "+965",
  Kyrgyzstan: "+996",
  Laos: "+856",
  Latvia: "+371",
  Lebanon: "+961",
  Lesotho: "+266",
  Liberia: "+231",
  Libya: "+218",
  Liechtenstein: "+423",
  Lithuania: "+370",
  Luxembourg: "+352",
  Macao: "+853",
  Madagascar: "+261",
  Malawi: "+265",
  Malaysia: "+60",
  Maldives: "+960",
  Mali: "+223",
  Malta: "+356",
  "Marshall Islands": "+692",
  Martinique: "+596",
  Mauritania: "+222",
  Mauritius: "+230",
  Mayotte: "+262",
  Mexico: "+52",
  Micronesia: "+691",
  Moldova: "+373",
  Monaco: "+377",
  Mongolia: "+976",
  Montenegro: "+382",
  Montserrat: "+1-664",
  Morocco: "+212",
  Mozambique: "+258",
  Myanmar: "+95",
  Namibia: "+264",
  Nauru: "+674",
  Nepal: "+977",
  Netherlands: "+31",
  "New Caledonia": "+687",
  "New Zealand": "+64",
  Nicaragua: "+505",
  Niger: "+227",
  Nigeria: "+234",
  Niue: "+683",
  "North Korea": "+850",
  "North Macedonia": "+389",
  "Northern Mariana Islands": "+1-670",
  Norway: "+47",
  Oman: "+968",
  Pakistan: "+92",
  Palau: "+680",
  Panama: "+507",
  "Papua New Guinea": "+675",
  Paraguay: "+595",
  Peru: "+51",
  Philippines: "+63",
  Poland: "+48",
  Portugal: "+351",
  "Puerto Rico": "+1-787",
  Qatar: "+974",
  Réunion: "+262",
  Romania: "+40",
  Russia: "+7",
  Rwanda: "+250",
  "Saint Kitts and Nevis": "+1-869",
  "Saint Lucia": "+1-758",
  "Saint Vincent and the Grenadines": "+1-784",
  Samoa: "+685",
  "San Marino": "+378",
  "Sao Tome and Principe": "+239",
  "Saudi Arabia": "+966",
  Senegal: "+221",
  Serbia: "+381",
  Seychelles: "+248",
  "Sierra Leone": "+232",
  Singapore: "+65",
  "Sint Maarten": "+1-721",
  Slovakia: "+421",
  Slovenia: "+386",
  "Solomon Islands": "+677",
  Somalia: "+252",
  "South Africa": "+27",
  "South Korea": "+82",
  "South Sudan": "+211",
  Spain: "+34",
  "Sri Lanka": "+94",
  "St. Vincent and the Grenadines": "+1-784",
  "State of Palestine": "+970",
  Sudan: "+249",
  Suriname: "+597",
  Sweden: "+46",
  Switzerland: "+41",
  Syria: "+963",
  Taiwan: "+886",
  Tajikistan: "+992",
  Tanzania: "+255",
  Thailand: "+66",
  "Timor-Leste": "+670",
  Togo: "+228",
  Tokelau: "+690",
  Tonga: "+676",
  "Trinidad and Tobago": "+1-868",
  Tunisia: "+216",
  Turkey: "+90",
  Turkmenistan: "+993",
  "Turks and Caicos Islands": "+1-649",
  Tuvalu: "+688",
  Uganda: "+256",
  Ukraine: "+380",
  "United Arab Emirates": "+971",
  "United Kingdom": "+44",
  "United States": "+1",
  Uruguay: "+598",
  Uzbekistan: "+998",
  Vanuatu: "+678",
  Venezuela: "+58",
  Vietnam: "+84",
  "Wallis and Futuna": "+681",
  "Western Sahara": "+212",
  Yemen: "+967",
  Zambia: "+260",
  Zimbabwe: "+263",
};

// Required local digits per country (same as primary)
const LOCAL_DIGITS_REQUIRED: Record<string, number> = {
  India: 10,
  Bangladesh: 10,
  USA: 10,
};

// ---- Phone helpers ----
function normalizeLocalDigits(input: string, dialCode: string): string {
  let val = (input || "").trim();
  if (val.startsWith(dialCode)) val = val.slice(dialCode.length);
  val = val.replace(/[^0-9]/g, "");  // digits only
  val = val.replace(/^0+/, "");      // remove trunk zeros
  return val;
}
function requiredLocalDigits(country: string): number {
  return LOCAL_DIGITS_REQUIRED[country] ?? 10;
}
function toE164(dialCode: string, input: string): string {
  const local = normalizeLocalDigits(input, dialCode);
  return `${dialCode}${local}`;
}


export default function WelcomeContent() {
 const { t, i18n, ready } = useTranslation(undefined, { useSuspense: false });
  const router = useRouter();

  const { languageOptions = [], loading: loadingLanguages } = useLanguageOptions();
  const { countries = [], statesByCountry = {}, loading: loadingCountries } =
    useCountryStateOptions();

  const [selectedCountry, setSelectedCountry] = useState(() => {
    if (typeof window !== "undefined") {
      return localStorage.getItem("selectedCountryName") || countries[0] || "India";
    }
    return "India";
  });

  const [selectedState, setSelectedState] = useState("");
  const [selectedLanguage, setSelectedLanguage] = useState(() => {
    if (typeof window !== "undefined") {
      return localStorage.getItem("language") || i18n.language || "en";
    }
    return "en";
  });

  const [referralCode, setReferralCode] = useState("");
  const [mobileNumber, setMobileNumber] = useState("");
  const [acceptedTerms, setAcceptedTerms] = useState(false);
 const [isReady, setIsReady] = useState(true);
  const [referralValid, setReferralValid] = useState<boolean | null>(null);
  const [mobileValid, setMobileValid] = useState<boolean | null>(null);
  const [validatingReferral, setValidatingReferral] = useState(false);
  const [validatingMobile, setValidatingMobile] = useState(false);
  const mobileReqId = useRef(0);
  const isValidatingMobileRef = useRef(false);
const mobileAbortRef = useRef<AbortController | null>(null);
// Inline referral status message (keep these)
const [referralMsg, setReferralMsg] = useState<string | null>(null);
const [referralMsgType, setReferralMsgType] =
  useState<"success" | "error" | "note" | null>(null);

// Mobile inline message state (single source of truth)
const [mobileMsg, setMobileMsg] = useState<string | null>(null);
const [mobileMsgType, setMobileMsgType] =
  useState<"success" | "error" | "note" | null>(null);

// ⬇️ BLOCK B — Recovery mobile state
const [recoveryMobile, setRecoveryMobile] = useState<string>(() => {
  if (typeof window !== "undefined") {
    return localStorage.getItem("recoveryMobile") || "";
  }
  return "";
});
const [recoveryMsg, setRecoveryMsg] = useState<string | null>(null);
const [recoveryMsgType, setRecoveryMsgType] =
  useState<"success" | "error" | "note" | null>(null);
// ⬆️ End BLOCK B

// ⬇️ BLOCK H — OTP state (primary mobile)
const [otp, setOtp] = useState<string>("");
const [otpSent, setOtpSent] = useState<boolean>(false);
const [otpVerified, setOtpVerified] = useState<boolean>(false); // optional gate for Join
const [otpLoading, setOtpLoading] = useState<"send" | "verify" | null>(null);
const [otpMsg, setOtpMsg] = useState<string | null>(null);
const [otpMsgType, setOtpMsgType] = useState<"success" | "error" | "note" | null>(null);
const [resendIn, setResendIn] = useState<number>(0);
const otpTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);
// ⬆️ End BLOCK H


  const [translations, setTranslations] = useState<Record<string, string>>({});
  const tOverride = (key: string) => translations[key] || t(key);

  const dialCode = countryDialingCodes[selectedCountry] || "+91";

  // Reset mobile validation when user edits number
  useEffect(() => {
    setMobileValid(null);
  }, [mobileNumber]);

  // Persist recovery mobile on change
useEffect(() => {
  try { localStorage.setItem("recoveryMobile", recoveryMobile); } catch {}
}, [recoveryMobile]);


  // i18n readiness — rely on `ready` from react-i18next (no `.on` listener)
useEffect(() => {
  if (ready || i18n?.isInitialized) {
    setIsReady(true);
  }
}, [ready, i18n?.isInitialized]);


  // persist selected country
  useEffect(() => {
    try {
      localStorage.setItem("selectedCountryName", selectedCountry);
    } catch {}
  }, [selectedCountry]);

  // pick initial language if empty
  useEffect(() => {
    if (selectedLanguage) return;

    const saved =
      (typeof window !== "undefined" && localStorage.getItem("language")) || "";
    if (saved) {
      setSelectedLanguage(saved.toLowerCase());
      return;
    }
    const en = languageOptions.find((l: any) => langCodeFrom(l) === "en");
    if (en) {
      setSelectedLanguage("en");
      return;
    }
    if (languageOptions.length) {
      const first = langCodeFrom(languageOptions[0]);
      if (first) setSelectedLanguage(first);
    }
  }, [languageOptions, selectedLanguage]);

  // keep i18n in sync with selectedLanguage
  useEffect(() => {
    if (!selectedLanguage) return;
    try {
      localStorage.setItem("language", selectedLanguage);
    } catch {}
    if (i18n?.changeLanguage && (i18n.language || "").toLowerCase() !== selectedLanguage) {
      i18n.changeLanguage(selectedLanguage);
    }
  }, [selectedLanguage, i18n]);

  // when country changes, keep state if still valid; otherwise clear
  useEffect(() => {
    if (!selectedCountry) {
      setSelectedState("");
      return;
    }
    const list = (statesByCountry as Record<string, any[]>)[selectedCountry] || [];
    setSelectedState((prev) => {
  if (!prev) return prev;
  if (prev === ALL_STATES) return prev;
  const exists = list.some((it) => (typeof it === "string" ? it : (it as any).name) === prev);
  return exists ? prev : "";
});

  }, [selectedCountry, statesByCountry]);

// strip any typed country code from mobile + recovery when country changes
useEffect(() => {
  if (!selectedCountry) return;
  const allPrefixes = Object.values(countryDialingCodes);

  // primary
  let updatedPrimary = mobileNumber;
  for (const p of allPrefixes) {
    if (updatedPrimary.startsWith(p)) {
      updatedPrimary = updatedPrimary.slice(p.length);
      break;
    }
  }

  // recovery
  let updatedRecovery = recoveryMobile;
  for (const p of allPrefixes) {
    if (updatedRecovery.startsWith(p)) {
      updatedRecovery = updatedRecovery.slice(p.length);
      break;
    }
  }

  setMobileNumber(updatedPrimary);
  setRecoveryMobile(updatedRecovery);
}, [selectedCountry]); // eslint-disable-line react-hooks/exhaustive-deps

// load dynamic translations from Supabase (never fails: exact → base → en(DB) → built-in EN)
useEffect(() => {
  if (!i18n?.isInitialized) return;

  const desired = normalizeLang(i18n.language || "en");

  const tryGet = async (
    column: "language_iso_code" | "language_code",
    code: string
  ) =>
    supabase
      .from("translations")
      .select("translations")
      .eq(column, code)
      .maybeSingle();

  const fetchBundle = async (code: string) => {
    let res = await tryGet("language_iso_code", code);
    if (!res.data?.translations) res = await tryGet("language_code", code);
    return (res.data?.translations as Record<string, any> | undefined) || null;
  };

  (async () => {
    let used = desired;
    let bundle = await fetchBundle(used); // 1) exact (e.g., "hu-hu")

    if (!bundle) {
      const base = used.split("-")[0];
      if (base && base !== used) {
        const baseBundle = await fetchBundle(base); // 2) base (e.g., "hu")
        if (baseBundle) {
          bundle = baseBundle;
          used = base;
        }
      }
    }

    if (!bundle) {
      const enBundle = await fetchBundle("en"); // 3) English from DB
      if (enBundle) {
        bundle = enBundle;
        used = "en";
      }
    }

    if (!bundle) {
      // 4) Built-in English (FALLBACK_EN must be defined at module scope)
      bundle = FALLBACK_EN;
      used = "en";
    }

    setTranslations(bundle);
    try {
      i18n.addResourceBundle(used, "translation", bundle, true, true);
      if (normalizeLang(i18n.language) !== used) i18n.changeLanguage(used);
    } catch {
      /* no-op */
    }
  })();
}, [i18n.isInitialized, i18n.language]);


  // ========== FIXED: single, clean definition ==========
// ========== FIXED: single, clean definition ==========
async function validateReferralWithAPI() {
 const trimmed = padINTA((referralCode || "").trim());
  if (!trimmed) {
    const msg = "Please enter referral code.";
    alert(msg);
    setReferralValid(null);
    setReferralMsg(msg);
    setReferralMsgType("error");
    return;
  }

  if (validatingReferral) return; // guard duplicate clicks

  // clear any previous message while we start a fresh validation
  setReferralMsg(null);
  setReferralMsgType(null);

  setValidatingReferral(true);
  try {
    // 1) Parse the intended country/state from the referral text
const suggestion = parseReferralToSuggestion(trimmed, countries, statesByCountry);

if (suggestion) {
  const requiredCountry = suggestion.country;
  const requiredState = suggestion.state || ALL_STATES;

  // 2) Enforce country selection first
  if (!selectedCountry || selectedCountry !== requiredCountry) {
    const msg = `Select ${requiredCountry} in Select country code column`;
    alert(msg);
    setReferralValid(null);           // do NOT mark as invalid; just show guidance
    setReferralMsg(msg);
    setReferralMsgType("error");
    const el = document.getElementById("country") as HTMLSelectElement | null;
    el?.scrollIntoView({ behavior: "smooth", block: "center" });
    el?.focus();
    return;
  }

  // 3) Enforce state next (or "All States" when the referral has no state)
  const needsAllStates = requiredState === ALL_STATES;
  const stateOK = needsAllStates
    ? selectedState === ALL_STATES
    : selectedState === requiredState;

  if (!stateOK) {
    const msg = `Select ${needsAllStates ? ALL_STATES : requiredState} in Select state code column`;
    alert(msg);
    setReferralValid(null);           // do NOT mark as invalid; just show guidance
    setReferralMsg(msg);
    setReferralMsgType("error");
    const el = document.getElementById("state") as HTMLSelectElement | null;
    el?.scrollIntoView({ behavior: "smooth", block: "center" });
    el?.focus();
    return;
  }
} else {
  // If the referral couldn't be parsed, require explicit selections
  if (!selectedCountry || !selectedState) {
    const msg = "Please select Country and State before validating the referral.";
    alert(msg);
    setReferralValid(null);           // guidance, not "invalid"
    setReferralMsg(msg);
    setReferralMsgType("error");
    const el = (!selectedCountry
      ? document.getElementById("country")
      : document.getElementById("state")) as HTMLSelectElement | null;
    el?.scrollIntoView({ behavior: "smooth", block: "center" });
    el?.focus();
    return;
  }
}

    // 4) Country/State match the referral — call the server
    const type: "aa" | "child" | "auto" = isAASeed(trimmed) ? "aa" : "child";

    const { valid, error, reason } = await validateReferralAndMobileAPI(
      trimmed,
      "",          // no mobile here
      type,        // ONLY admin AA seeds go as "aa"; everything else "child"
      selectedCountry,
      selectedState
    );

    setReferralValid(!!valid);

    if (!valid) {
      const msg = error || `Referral invalid (${reason || "UNKNOWN"})`;
      alert(msg);
      setReferralMsg(msg);               // show exact server message inline
      setReferralMsgType("error");
      return;
    }

    const okMsg = "Referral code is valid ✅";
    alert(okMsg);
    setReferralMsg(okMsg);
    setReferralMsgType("success");
    // After referral success, check AA→AB≥95% gate and store the flag
await checkConnectorsGateByReferral(trimmed);

  } catch (err: any) {
    setReferralValid(false);
    const msg = err?.message || "Unable to connect to server";
    alert(msg);
    setReferralMsg(msg);
    setReferralMsgType("error");
  } finally {
    setValidatingReferral(false);
  }
}

// ⬇️ BLOCK L — Check Connectors gate via Supabase RPC
async function checkConnectorsGateByReferral(ref: string) {
  const trimmed = (ref || "").trim();
  if (!trimmed) {
    setAllowConnectors(true);   // no ref → no gate
    setGateInfo(null);
    return;
  }
  try {
    const { data, error } = await supabase.rpc("is_aa_connectors_tab_unlocked", { p_ref: trimmed });
    if (error) {
      console.warn("[gate] RPC error:", error.message);
      setAllowConnectors(true); // fail open
      setGateInfo(null);
      return;
    }
    const row = Array.isArray(data) ? data[0] : data;
    const isAA = !!row?.is_aa;
    const businessPct = typeof row?.business_pct === "number" ? row.business_pct : null;
    const unlocked = !!row?.unlocked;

    setGateInfo({ isAA, businessPct, unlocked });
    setAllowConnectors(isAA ? unlocked : true); // non-AA → always allowed
  } catch (e: any) {
    console.warn("[gate] exception:", e?.message || e);
    setAllowConnectors(true); // fail open
    setGateInfo(null);
  }
}
// ⬆️ End BLOCK L


// ↓ Add this inside WelcomeContent(), anywhere above `return ( ... )`
async function validateMobileWithAPI() {
  // must validate referral first
  if (!referralValid) {
    alert("Please validate referral code first.");
    return;
  }

  // basic mobile checks
  if (!mobileNumber.trim()) {
    alert("Please enter a mobile number.");
    return;
  }

  // require both country & state before mobile validation
  if (!selectedCountry || !selectedState) {
    alert("Please select Country and State before validating the mobile.");
    return;
  }

 
  // Block double invocations (ref + state) in one shot
if (isValidatingMobileRef.current || validatingMobile) return;
isValidatingMobileRef.current = true;
setValidatingMobile(true);


  // Abort any in-flight mobile validation before starting a new one
  if (mobileAbortRef.current) {
    try { mobileAbortRef.current.abort(); } catch {}
  }
  const controller = new AbortController();
  mobileAbortRef.current = controller;

  // Only process the latest response
  const myReq = (mobileReqId.current = (mobileReqId.current || 0) + 1);
  setMobileMsg(null);
setMobileMsgType(null);


  try {
    const trimmedCode = padINTA((referralCode || "").trim());

    // build full E.164-like number: <dialCode><local part>
    const allPrefixes = Object.values(countryDialingCodes);
    let localPart = mobileNumber.trim();

    // remove any dial code the user may have typed
    for (const p of allPrefixes) {
      if (localPart.startsWith(p)) {
        localPart = localPart.slice(p.length);
        break;
      }
    }
    // remove leading trunk zeros
    localPart = localPart.replace(/^0+/, "");

    const fullMobile = `${dialCode}${localPart}`; // e.g. +91 9876543210

    const type: "aa" | "child" | "auto" = isAASeed(trimmedCode) ? "aa" : "child";

    const { valid, error, reason } = await validateReferralAndMobileAPI(
      trimmedCode,
      fullMobile,
      type,                 // ONLY AA seeds go as "aa"; everything else "child"
      selectedCountry,
      selectedState,
      { signal: controller.signal } // ✅ pass abort signal
    );

    // Ignore stale or aborted responses
    if (myReq !== mobileReqId.current || reason === "ABORTED") return;

    setMobileValid(!!valid);

if (valid) {
  const okMsg =
    type === "aa"
      ? "AA referral and mobile match ✅"
      : "Referral code and mobile number combination is valid ✅";
  alert(okMsg);
  setMobileMsg(okMsg);
  setMobileMsgType("success");
  return;
}


    // 🔹 AA-specific: show the exact server message for aa_connectors failures
   if (reason === "MOBILE_EXISTS") {
  const msg = error || "Mobile number already registered.";
  alert(msg);
  setMobileValid(false);
  setMobileMsg(msg);
  setMobileMsgType("error");
  return;
}
if (reason === "MOBILE_ALREADY_ON_TREE") {
  const msg = error || "This mobile is already registered under the same referral.";
  alert(msg);
  setMobileValid(false);
  setMobileMsg(msg);
  setMobileMsgType("error");
  return;
}
if (reason === "MOBILE_BELONGS_TO_OTHER") {
  const msg = error || "This mobile is already registered under a different referral.";
  alert(msg);
  setMobileValid(false);
  setMobileMsg(msg);
  setMobileMsgType("error");
  return;
}
if (reason === "COUNTRY_MISMATCH" || reason === "STATE_MISMATCH") {
  const msg = error || "Country/State mismatch with referral.";
  alert(msg);
  setMobileValid(false);
  setMobileMsg(msg);
  setMobileMsgType("error");
  return;
}

// default
{
  const msg = error || "Referral code and mobile number do not match ❌";
  alert(msg);
  setMobileValid(false);
  setMobileMsg(msg);
  setMobileMsgType("error");
  return;
}


      } catch (err: any) {
    // If an AbortError slipped through, do nothing
    if (err?.name !== "AbortError") {
  console.error("Validation error:", err);
  const msg = err?.message || "Unable to connect to server";
  alert(msg);
  setMobileValid(false);
  setMobileMsg(msg);
  setMobileMsgType("error");
}

  } finally {
    // Only the latest request clears the spinner & flags
    if (myReq === mobileReqId.current) {
      setValidatingMobile(false);
      isValidatingMobileRef.current = false;
      if (mobileAbortRef.current === controller) mobileAbortRef.current = null;
    }
  }
}

// ⬇️ BLOCK I — OTP helpers/handlers
function clearOtpTimer() {
  if (otpTimerRef.current) {
    clearInterval(otpTimerRef.current);
    otpTimerRef.current = null;
  }
}
function startResendTimer(seconds = 59) {
  clearOtpTimer();
  setResendIn(seconds);
  otpTimerRef.current = setInterval(() => {
    setResendIn((s) => {
      if (s <= 1) {
        clearOtpTimer();
        return 0;
      }
      return s - 1;
    });
  }, 1000);
}

// Reset OTP flow whenever mobile changes or mobile validity resets
useEffect(() => {
  setOtp("");
  setOtpSent(false);
  setOtpVerified(false);
  setOtpMsg(null);
  setOtpMsgType(null);
  setResendIn(0);
  clearOtpTimer();
}, [mobileNumber, dialCode, mobileValid]);

// Cleanup on unmount
useEffect(() => {
  return () => clearOtpTimer();
}, []);

async function handleSendOtp() {
  // Preconditions: referral + mobile validated
  if (!referralValid) {
    alert("Please validate referral code first.");
    return;
  }
  if (!mobileValid) {
    alert("Please validate mobile number first.");
    return;
  }
  if (!selectedCountry || !selectedState) {
    alert("Please select Country and State.");
    return;
  }

  const fullMobile = toE164(dialCode, mobileNumber);

  setOtpLoading("send");
  setOtpMsg(null);
  setOtpMsgType(null);
  try {
    const r = await fetch("/api/otp/send", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ mobile: fullMobile }),
    });
    const data = await r.json().catch(() => ({}));
    if (!r.ok || data?.error) {
      const msg = data?.error || `OTP send failed (HTTP_${r.status})`;
      setOtpMsg(msg);
      setOtpMsgType("error");
      alert(msg);
      return;
    }
    setOtpSent(true);
    setOtpMsg("OTP sent to your mobile ✅");
    setOtpMsgType("success");
    startResendTimer(30); // cooldown before resend
  } catch (e: any) {
    const msg = e?.message || "Unable to send OTP";
    setOtpMsg(msg);
    setOtpMsgType("error");
    alert(msg);
  } finally {
    setOtpLoading(null);
  }
}

async function handleVerifyOtp() {
  if (!otpSent) {
    alert("Please send OTP first.");
    return;
  }
  const code = (otp || "").trim();
  if (!/^\d{4,8}$/.test(code)) {
    alert("Enter the OTP (4–8 digits).");
    return;
  }

  const fullMobile = toE164(dialCode, mobileNumber);

  setOtpLoading("verify");
  try {
    const r = await fetch("/api/otp/verify", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ mobile: fullMobile, otp: code }),
    });
    const data = await r.json().catch(() => ({}));
    if (!r.ok || data?.error) {
      const msg = data?.error || `OTP verify failed (HTTP_${r.status})`;
      setOtpMsg(msg);
      setOtpMsgType("error");
      alert(msg);
      setOtpVerified(false);
      return;
    }
    setOtpMsg("Mobile number verified via OTP ✅");
    setOtpMsgType("success");
    setOtpVerified(true);
  } catch (e: any) {
    const msg = e?.message || "Unable to verify OTP";
    setOtpMsg(msg);
    setOtpMsgType("error");
    alert(msg);
    setOtpVerified(false);
  } finally {
    setOtpLoading(null);
  }
}
// ⬆️ End BLOCK I

// ⬇️ BLOCK K — Connectors tab gate (AA ≥95% business)
const [allowConnectors, setAllowConnectors] = useState<boolean>(true);
const [gateInfo, setGateInfo] = useState<{
  isAA: boolean;
  businessPct: number | null;
  unlocked: boolean;
} | null>(null);
// ⬆️ End BLOCK K

  function validateForm() {
  if (!referralValid) {
    alert("Please validate referral code first.");
    return false;
  }
  if (!mobileValid) {
    alert("Please validate mobile number.");
    return false;
  }

  // --- Recovery mobile checks (required, format, length, distinct) ---
  const trimmedRecovery = (recoveryMobile || "").trim();
  if (!trimmedRecovery) {
    const msg = "Please enter recovery mobile number.";
    alert(msg);
    setRecoveryMsg(msg);
    setRecoveryMsgType("error");
    return false;
  }

  const need = requiredLocalDigits(selectedCountry);
  const recLocal = normalizeLocalDigits(trimmedRecovery, dialCode);
  if (recLocal.length !== need) {
    const msg = `Invalid recovery mobile length for ${selectedCountry}. Expected ${need} digits.`;
    alert(msg);
    setRecoveryMsg(msg);
    setRecoveryMsgType("error");
    return false;
  }

  const fullPrimary = toE164(dialCode, mobileNumber);
  const fullRecovery = toE164(dialCode, trimmedRecovery);
  if (fullPrimary === fullRecovery) {
    const msg = "Mobile number and recovery mobile number cannot be same.";
    alert(msg);
    setRecoveryMsg(msg);
    setRecoveryMsgType("error");
    return false;
  }

  if (!acceptedTerms) {
    alert(t("alert.accept_terms"));
    return false;
  }

  // Passed all checks
  setRecoveryMsg(null);
  setRecoveryMsgType(null);
  return true;
}



  function handleJoin() {
  if (validatingReferral || validatingMobile) {
    alert("Please wait for validation to complete.");
    return;
  }
  if (!validateForm()) return;

  const selectedLanguageObj =
  languageOptions.find((l: any) =>
    String(l.code ?? l.language_code ?? l.language_iso_code ?? "")
      .toLowerCase() === (selectedLanguage || "").toLowerCase()
  ) ||
  languageOptions.find((l: any) => {
    const display = String(l.display_name ?? l.label_native ?? l.label ?? "").toLowerCase();
    return display === (selectedLanguage || "").toLowerCase();
  });


  const languageNameToISO: Record<string, string> = {
    afrikaans: "af", albanian: "sq", amharic: "am", arabic: "ar", armenian: "hy",
    azerbaijani: "az", bangla: "bn-BD", basque: "eu-ES", belarusian: "be", bengali: "bn",
    bulgarian: "bg", burmese: "my-MM", catalan: "ca", chinese_hk: "zh-HK", chinese_simplified: "zh-CN",
    chinese_traditional: "zh-TW", croatian: "hr", czech: "cs", danish: "da", de: "de", dutch: "nl",
    egyptian_arabic: "arz", english: "en", "english (australia)": "en-AU", "english (canada)": "en-CA",
    "english (united kingdom)": "en-GB", estonian: "et", filipino: "tl", finnish: "fi", french: "fr",
    french_canada: "fr-CA", french_france: "fr-FR", galician: "gl", georgian: "ka", german: "de",
    greek: "el", gujarati: "gu", hebrew: "he", hindi: "hi", hungarian: "hu", icelandic: "is",
    indonesian: "id", italian: "it", japanese: "ja", kannada: "kn", kazakh: "kk", khmer: "km",
    korean: "ko", kyrgyz: "ky", lao: "lo", latvian: "lv", lithuanian: "lt", macedonian: "mk",
    malay: "ms", malay_malaysia: "ms-MY", malayalam: "ml", mandarin_chinese: "zh", marathi: "mr",
    mongolian: "mn", nepali: "ne", nigerian_pidgin: "pcm", norwegian: "no", persian: "fa", polish: "pl",
    portuguese: "pt", portuguese_brazil: "pt-BR", portuguese_portugal: "pt-PT", punjabi: "pa",
    romanian: "ro", romansh: "rm", russian: "ru", serbian: "sr", sinhala: "si-LK", slovak: "sk",
    slovenian: "sl", spanish: "es", spanish_latam: "es-419", spanish_spain: "es-ES", swahili: "sw",
    swedish: "sv", tamil: "ta", telugu: "te", thai: "th", turkish: "tr", ukrainian: "uk",
    urdu: "ur", vietnamese: "vi", zulu: "zu",
  };

  const langCode =
    (selectedLanguageObj?.code ||
      selectedLanguageObj?.language_code ||
      languageNameToISO[(selectedLanguage || "").toLowerCase()] ||
      selectedLanguage ||
      "en").toLowerCase();

  const languageLabel =
    selectedLanguageObj?.display_name ||
    (selectedLanguageObj as any)?.label_native ||
    (selectedLanguageObj as any)?.label ||
    selectedLanguage;

  // Build normalized E.164 numbers
  const fullPrimary = toE164(dialCode, mobileNumber);
  const fullRecovery = toE164(dialCode, recoveryMobile);

  // Persist recovery mobile (already persisted onChange, but safe here too)
  try { localStorage.setItem("recoveryMobile", recoveryMobile); } catch {}

  router.push(
    `/onboarding-tabs?ref=${encodeURIComponent(referralCode.trim())}` +
      `&country=${encodeURIComponent(selectedCountry)}` +
      `&state=${encodeURIComponent(selectedState)}` +
      `&mobile=${encodeURIComponent(fullPrimary)}` +
      `&recoveryMobile=${encodeURIComponent(fullRecovery)}` +
      `&lang=${encodeURIComponent(langCode)}` +
      `&langLabel=${encodeURIComponent(languageLabel)}` +
      `&prefix=${encodeURIComponent(dialCode)}`+
      (otpVerified ? `&otp=1` : ``) +
    `&allowConnectors=${allowConnectors ? "1" : "0"}`
  );
}


  if (!isReady) return null;


  return (
   <div className="min-h-screen w-full max-w-[720px] mx-auto px-4 sm:px-6 py-6 bg-white text-black font-sans">

      <div className="mt-20 mb-8 text-center space-y-1 sm:space-y-2 md:space-y-3">
        <h1 className="text-3xl sm:text-4xl md:text-5xl font-bold text-blue-700 leading-snug uppercase break-words">
          {tOverride("welcome_to")}
        </h1>
        <h1 className="text-4xl sm:text-5xl font-extrabold text-blue-800 uppercase tracking-wide">
          CONNECTA
        </h1>
        <p className="text-base sm:text-lg text-gray-600 leading-normal">
          {tOverride("capitalize_your_contacts")}
        </p>
      </div>

      <img src="/connecta-logo.png" alt="Connecta Logo" className="w-32 h-32 mb-4 mx-auto" />

      {/* Referral */}
      <textarea
        rows={4}
        placeholder={tOverride("enter_referral_placeholder")}
        value={referralCode}
        onChange={(e) => setReferralCode(e.target.value)}
        className="border rounded-lg p-3 w-full mb-1 resize-none text-black"
      />
      <div className="text-sm text-gray-700 mb-3 text-center">
        <span className="text-blue-600 font-medium">India_Tamilnadu_M253540</span> {" "}or{" "}
        <span className="text-green-600 font-medium">India_Tamil Nadu_INTAAA000000004_Mary</span>
      </div>
    

{referralMsg && (
  <p
    className={`mb-4 text-center text-lg font-semibold ${
      referralMsgType === "success" ? "text-green-600" :
      referralMsgType === "error" ? "text-red-600" :
      "text-blue-600"
    }`}
  >
    {referralMsg}
  </p>
)}

{/** ⬇️ BLOCK M — Gate status note (optional) */}
{gateInfo && gateInfo.isAA && (
  <p className="mb-4 text-center text-sm">
    {typeof gateInfo.businessPct === "number" ? (
      gateInfo.unlocked ? (
        <span className="text-green-600 font-semibold">
          AB “business” = {gateInfo.businessPct}% — Connectors tab unlocked.
        </span>
      ) : (
        <span className="text-amber-700 font-semibold">
          AB “business” = {gateInfo.businessPct}% — Connectors tab locked until ≥ 95%.
        </span>
      )
    ) : (
      <span className="text-gray-600">Checking AB split…</span>
    )}
  </p>
)}
{/** ⬆️ End BLOCK M */}



      {/* Country */}
      <div className="mb-4 w-full text-center">
        <label className="block mb-1 text-lg font-medium text-gray-800">🌍 Select Country</label>
        <div className="w-full max-w-md mx-auto">
          <select
            id="country"
            value={selectedCountry}
            onChange={(e) => setSelectedCountry(e.target.value)}
            className="border border-gray-400 p-3 rounded-lg w-full bg-white text-black focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="">-- Select --</option>
            {countries.map((country, idx) => (
              <option key={`${country}-${idx}`} value={country}>
                {country}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* State */}
      <div className="mb-4 w-full text-center">
        <label className="block mb-1 text-lg font-medium text-gray-800">📍 Select State</label>
        <div className="w-full max-w-md mx-auto">
          <select
            id="state"
            value={selectedState}
            onChange={(e) => setSelectedState(e.target.value)}
            className="border border-gray-400 p-3 rounded-lg w-full bg-white text-black focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="">-- Select --</option>
          <option value={ALL_STATES}>{ALL_STATES}</option>
            {(statesByCountry as Record<string, any[]>)[selectedCountry]?.map((state, idx) => {
              const val = typeof state === "string" ? state : (state as any).name || "";
              return (
                <option key={`state-${val}-${idx}`} value={val}>
                  {val}
                </option>
              );
            })}
          </select>
        </div>
      </div>
      
      <button
  onClick={() => {
    console.log("🟦 referral button → API");
    validateReferralWithAPI();
  }}
  disabled={validatingReferral}
  className={`mb-4 px-6 py-2 rounded text-white ${
    validatingReferral ? "bg-gray-400 cursor-not-allowed" : "bg-blue-600 hover:bg-blue-700"
  }`}
>
  {validatingReferral ? "Validating..." : "Validate Referral Code"}
</button>

      {/* Language */}
      <div className="mb-4 w-full text-center">
        <label className="block mb-1 text-lg font-medium text-gray-800">🌐 Select Language</label>
        <div className="w-full max-w-md mx-auto">
          <select
            id="language"
            value={selectedLanguage || ""} // single source of truth
            onChange={(e) => {
              const code = (e.target.value || "").toLowerCase().replace("_", "-");
              setSelectedLanguage(code);
              try {
                localStorage.setItem("language", code);
              } catch {}
              if (i18n?.changeLanguage) i18n.changeLanguage(code);
            }}
            className="border border-gray-400 p-3 rounded-lg w-full bg-white text-black focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="">{tOverride("select_language")}</option>
            {(() => {
              const seen = new Set<string>();
              return languageOptions.map((lang: any, idx: number) => {
                const { code, label } = buildLangLabel(lang);
                if (!code || seen.has(code)) return null;
                seen.add(code);
                return (
                  <option key={`${code}-${idx}`} value={code}>
                    {label}
                  </option>
                );
              });
            })()}
          </select>
        </div>
      </div>

      {/* Mobile */}
      <div className="mb-2 w-full text-center relative">
        <textarea
          rows={2}
          placeholder={tOverride("enter_mobile_placeholder")}
          value={mobileNumber}
         onChange={(e) => {
  let val = e.target.value;
  if (val.startsWith(dialCode)) val = val.slice(dialCode.length);
  setMobileNumber(val);
  setMobileValid(null);
  setMobileMsg(null);
  setMobileMsgType(null);
}}

          className="border rounded-lg p-3 pl-14 w-full text-black resize-none"
          disabled={!referralValid}
        />
        <span className="absolute left-3 top-4 transform -translate-y-1 text-gray-600 font-semibold select-none">
          {dialCode}
        </span>
      </div>

      <button
        onClick={validateMobileWithAPI}
        disabled={!referralValid || validatingMobile}
        className={`mb-4 px-6 py-2 rounded text-white ${
          !referralValid || validatingMobile
            ? "bg-gray-400 cursor-not-allowed"
            : "bg-blue-600 hover:bg-blue-700"
        }`}
      >
        {validatingMobile ? "Validating..." : "Validate Mobile + Referral Code"}
      </button>

      {mobileMsg && (
  <p
    className={`mb-4 text-center text-lg font-semibold ${
      mobileMsgType === "success" ? "text-green-600" :
      mobileMsgType === "error" ? "text-red-600" :
      "text-blue-600"
    }`}
  >
    {mobileMsg}
  </p>
)}
{/* ⬇️ BLOCK J — OTP UI for primary mobile (Send → Input → Validate) */}
{mobileValid && (
  <div className="w-full mb-3">
    <label className="block mb-1 text-lg font-medium text-gray-800 text-center">
      🔐 OTP Verification
    </label>

    <div className="flex gap-2 items-center">
      {/* 1) Send OTP */}
      <button
        type="button"
        onClick={handleSendOtp}
        disabled={
          !referralValid ||
          !mobileValid ||
          validatingMobile ||
          otpLoading === "send" ||
          resendIn > 0 ||
          otpVerified
        }
        className={`px-4 py-2 rounded text-white ${
          !referralValid ||
          !mobileValid ||
          validatingMobile ||
          otpLoading === "send" ||
          resendIn > 0 ||
          otpVerified
            ? "bg-gray-400 cursor-not-allowed"
            : "bg-blue-600 hover:bg-blue-700"
        }`}
      >
        {otpVerified
          ? "Verified"
          : otpLoading === "send"
          ? "Sending..."
          : resendIn > 0
          ? `Resend in ${resendIn}s`
          : "Send OTP"}
      </button>

      {/* 2) OTP input */}
      <input
        type="text"
        inputMode="numeric"
        pattern="[0-9]*"
        placeholder="Enter OTP"
        value={otp}
        onChange={(e) => {
          const v = (e.target.value || "").replace(/\D/g, "").slice(0, 8);
          setOtp(v);
          setOtpMsg(null);
          setOtpMsgType(null);
        }}
        className="flex-1 border rounded-lg p-3 text-black"
        disabled={!otpSent || otpVerified}
      />

      {/* 3) Validate with OTP */}
      <button
        type="button"
        onClick={handleVerifyOtp}
        disabled={!otpSent || otpLoading === "verify" || otpVerified}
        className={`px-4 py-2 rounded text-white ${
          !otpSent || otpLoading === "verify" || otpVerified
            ? "bg-gray-400 cursor-not-allowed"
            : "bg-green-600 hover:bg-green-700"
        }`}
        title={!otpSent ? "Send OTP first" : ""}
      >
        {otpLoading === "verify" ? "Validating..." : "Validate with OTP"}
      </button>
    </div>

    {/* OTP inline message */}
    {otpMsg && (
      <p
        className={`mt-2 text-center text-sm font-semibold ${
          otpMsgType === "success"
            ? "text-green-600"
            : otpMsgType === "error"
            ? "text-red-600"
            : "text-blue-600"
        }`}
      >
        {otpMsg}
      </p>
    )}

    {/* Optional badge */}
    {otpVerified && (
      <p className="mt-1 text-center text-xs font-semibold text-green-600">
        Verified via OTP
      </p>
    )}
  </div>
)}
{/* ⬆️ End BLOCK J */}
{/* ⬇️ BLOCK G — Recovery Mobile */}
<div className="mb-2 w-full text-center relative">
  <textarea
    rows={2}
    placeholder={tOverride("enter_recovery_mobile_placeholder") || "Enter recovery mobile number"}
    value={recoveryMobile}
    onChange={(e) => {
      let val = e.target.value || "";
      if (val.startsWith(dialCode)) val = val.slice(dialCode.length);
      setRecoveryMobile(val);
      setRecoveryMsg(null);
      setRecoveryMsgType(null);
    }}
    className="border rounded-lg p-3 pl-14 w-full text-black resize-none"
    disabled={!referralValid}
  />
  <span className="absolute left-3 top-4 transform -translate-y-1 text-gray-600 font-semibold select-none">
    {dialCode}
  </span>
</div>

{recoveryMsg && (
  <p
    className={`mb-4 text-center text-lg font-semibold ${
      recoveryMsgType === "success" ? "text-green-600" :
      recoveryMsgType === "error" ? "text-red-600" :
      "text-blue-600"
    }`}
  >
    {recoveryMsg}
  </p>
)}
{/* ⬆️ End BLOCK G */}



{/* Terms */}
<div className="w-full flex justify-center mb-6">
  <label className="w-full max-w-[640px] mx-auto flex items-start sm:items-center justify-center gap-2 text-left">
    <input
      type="checkbox"
      checked={acceptedTerms}
      onChange={(e) => setAcceptedTerms(e.target.checked)}
      className="mt-1 sm:mt-0 h-4 w-4 accent-blue-600"
      aria-label={t("accept_terms")}
    />
    <span className="text-sm leading-5 text-gray-700">
      {t("accept_terms")}{" "}
      <a href="#" className="text-blue-600 underline">
        {t("terms_and_conditions")}
      </a>
    </span>
  </label>
</div>


      {/* Join */}
      <button
  onClick={handleJoin}
  disabled={
    !referralValid ||
    !mobileValid ||
    !otpVerified ||
    !acceptedTerms ||
    validatingReferral ||
    validatingMobile
  }
  className={`px-6 py-3 w-full rounded-2xl text-lg ${
    !referralValid ||
    !mobileValid ||
    !otpVerified ||
    !acceptedTerms ||
    validatingReferral ||
    validatingMobile
      ? "bg-gray-400 cursor-not-allowed"
      : "bg-green-600 hover:bg-green-700 text-white"
  }`}
>
  {t("join_connecta_community")}
</button>

    </div>
  );
}
