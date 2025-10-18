"use client";

import { Suspense, useState, useMemo, useEffect, useRef } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { supabase } from "@/lib/supabaseClient";
import { validatePincode } from "@/utils/pincode";
import { PhoneSummary, RegionLangSummary } from "@/components/ui/SummaryRows";
import { formatConnectaBadge } from "@/utils/formatConnectaBadge";
import PostJoinBadge from "@/components/ui/PostJoinBadge";


// i18n (so changing language actually swaps translations where used elsewhere)
import "@/lib/i18n";
import { useTranslation } from "react-i18next";

const countryNameToCC = (name?: string) => {
  const map: Record<string,string> = {
    India: "IN",
    Bangladesh: "BD",
    "United States": "US",
    USA: "US",
  };
  const n = String(name || "").trim();
  return map[n] || n.slice(0,2).toUpperCase();
};
// ---- helpers: make Supabase errors readable ----
function sbErrMessage(err: any): string {
  if (!err) return "Unknown Supabase error";
  if (typeof err === "string") return err;
  const m =
    (err.message ?? err.msg ?? err.error_description ?? err.error) ||
    (err.details ? String(err.details) : "") ||
    (err.hint ? String(err.hint) : "");
  return m || "Unknown Supabase error";
}

function sbErrSafeObject(err: any) {
  try {
    // stringify-safe snapshot for console
    return JSON.parse(JSON.stringify(err ?? null)) ?? null;
  } catch {
    return { message: (err && err.message) || String(err) };
  }
}

// INTAXX000000123[_X] → { level: 'XX', serial: '123' }
function parseINTAConnectaID(cid?: string | null): { level?: string; serial?: string } {
  const s = String(cid || "").trim();
  const m = s.match(/^INTA([A-Z]{2})(\d+)(?:_[A-Z])?$/i);
  if (!m) return {};
  return { level: m[1].toUpperCase(), serial: m[2].replace(/^0+(?=\d)/, "") };
}


// Keep consistent with your existing enum
const CONNECTOR_TYPES = {
  individual: "individual",
  business: "business",
  b2b: "b2b",
} as const;

export const dynamic = "force-dynamic";

export type BusinessVariant = "b2c" | "b2b" | "import" | "export";

const VARIANT_COPY: Record<
  BusinessVariant,
  {
    title: string;
    sub: string;
    connectorType: keyof typeof CONNECTOR_TYPES;
    subtype?: string;
    currencyNote: string;
    showIECode: boolean;
  }
> = {
  b2c: {
    title: "B2C Connectors",
    sub: "Small & Medium Businesses — ₹5,999 (waived for first year)",
    connectorType: "business",
    currencyNote: "INR",
    showIECode: false,
  },
  b2b: {
    title: "B2B Companies",
    sub: "Requires connections of businesses/factories, ₹14,999 (waived for first year)",
    connectorType: "business",   // ✅ was "b2b" — fix to store connector_type='business'
    currencyNote: "INR",
    showIECode: false,
    subtype: "b2b",              // ✅ record the variant as subtype
  },
  import: {
    title: "Import Connections",
    sub: "USD 599 (waived for first year)",
    connectorType: "business",
    subtype: "import",
    currencyNote: "USD",
    showIECode: true,
  },
  export: {
    title: "Export Connections",
    sub: "USD 599 (waived for first year)",
    connectorType: "business",
    subtype: "export",
    currencyNote: "USD",
    showIECode: true,
  },
};


const CLASSIFICATIONS_IN: readonly string[] = [
  "SUPER MARKET",
  "KIRANA / GENERAL STORE",
  "DEPARTMENTAL STORE",
  "RESTAURANT",
  "CAFE / TEA STALL",
  "BAKERY & CONFECTIONERY",
  "SWEETS & NAMKEEN SHOP",
  "PHARMACY / CHEMIST",
  "CLINIC / DIAGNOSTIC CENTER",
  "HOSPITAL / NURSING HOME",
  "SALON / BEAUTY PARLOUR",
  "SPA & WELLNESS",
  "GYM / FITNESS CENTER",
  "BOUTIQUE / TAILORING",
  "APPAREL / GARMENTS RETAIL",
  "FOOTWEAR STORE",
  "JEWELLERY / GOLD SHOP",
  "WATCHES & ACCESSORIES",
  "ELECTRONICS & APPLIANCES",
  "MOBILE & ACCESSORIES",
  "COMPUTER / IT SERVICES",
  "STATIONERY & BOOK STORE",
  "PRINTING / PHOTOCOPY / XEROX",
  "HARDWARE & SANITARY",
  "ELECTRICALS & LIGHTING",
  "FURNITURE & INTERIOR DECOR",
  "HOME DECOR / FURNISHINGS",
  "REAL ESTATE AGENT / PROPERTY DEALER",
  "TRAVEL AGENCY / TICKETING",
  "TOUR OPERATOR",
  "TAXI / TRANSPORT SERVICE",
  "AUTO GARAGE / MECHANIC",
  "AUTO SPARES & ACCESSORIES",
  "TWO-WHEELER DEALER / SERVICE",
  "AGRI INPUTS (SEEDS/FERTILIZER/PESTICIDES)",
  "DAIRY / MILK PRODUCTS",
  "MEAT & FISH SHOP",
  "FRUITS & VEGETABLES",
  "WHOLESALE TRADER",
  "DISTRIBUTOR / STOCKIST",
  "MANUFACTURER (MSME)",
  "PACKAGING MATERIALS",
  "EVENT MANAGEMENT / DECORATORS",
  "EDUCATION / COACHING CENTER",
  "PLAYSCHOOL / DAYCARE",
  "CATERING / TIFFIN SERVICE",
  "COURIER / LOGISTICS",
  "E-COMMERCE SELLER",
  "AC / FRIDGE / APPLIANCE REPAIR",
  "PLUMBER / ELECTRICIAN / CARPENTER",
  "OTHER",
] as const;

// -------- utils --------
const URL_RE =
  /^(https?:\/\/)?[\w.-]+(\.[\w.-]+)+[\w\-\._~:\/?#\[\]@!$&'()*+,;=.]*$/i;
const GSTIN_RE =
  /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/; // India GSTIN
const IEC_RE_NUM10 = /^\d{10}$/; // India IEC (legacy) – adjust as needed

function isURL(v: string) {
  return !v || URL_RE.test(v.trim());
}

function normalizePhone(raw: string) {
  const s = String(raw || "").trim();
  let cleaned = s.replace(/[^0-9+]/g, "");
  if (cleaned.startsWith("00")) cleaned = "+" + cleaned.slice(2);
  cleaned = cleaned.replace(/(?!^)\+/g, "");
  return cleaned;
}

// --- Hygiene helpers (Step 7) ---
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
function sanitizeProducts(
  products: Array<{ description?: string; [k: string]: any }>
) {
  return (products || []).map((p) => {
    const d = (p?.description || "").trim();
    // Policy: URLs not allowed in description
    return isLikelyUrl(d) ? { ...p, description: "" } : p;
  });
}
function deriveShortName(primary: string, provided?: string) {
  const chosen = (provided || "").trim() || (primary || "").trim();
  return chosen.slice(0, 14);
}


// Object key inside the bucket
function uniquePath(name: string) {
  const safe = name.toLowerCase().replace(/[^a-z0-9\-\.]+/g, "-").slice(0, 40);
  return `logos/${Date.now()}-${Math.random().toString(36).slice(2, 8)}-${safe}`;
}
type ScorePreview = {
  connector_type: "business" | "individual";
  score_out_of_100: number;
  score_percent: number;
  core_points: number;
  contact_points: number;
  rich_points: number;
  trust_points: number;
  products_count: number;
  missing_recommendations: string[];
};

function scoreBusinessPayload(p: any): ScorePreview {
  const missing: string[] = [];
  let core = 0, contact = 0, rich = 0, trust = 0;

  // Core (40)
  const hasCompany = !!(p.company || "").trim();
  const hasClass   = !!(p.classification || "").trim();
  const hasAddr1   = !!(p.addressLine1 || "").trim();
  const hasCity    = !!(p.city || "").trim();
  const hasPin     = !!(p.pincode || "").trim();

  core += hasCompany ? 10 : 0; if (!hasCompany) missing.push("Add company name");
  core += hasClass   ? 10 : 0; if (!hasClass)   missing.push("Add classification");
  core += hasAddr1   ? 10 : 0; if (!hasAddr1)   missing.push("Add address line 1");
  if (hasCity && hasPin) core += 10;
  else {
    if (!hasCity) missing.push("Add city/town/village");
    if (!hasPin)  missing.push("Add pincode");
  }

  // Contact (25)
  const hasEmail = !!(p.email || "").trim();
  const hasUpi   = !!(p.upi_id || "").trim();
  const links    = p.links || {};
  const hasAnyLink =
    !!(links.website || links.facebook || links.instagram || links.youtube || links.ytShorts || links.other);

  contact += hasEmail ? 10 : 0; if (!hasEmail) missing.push("Add email (optional)");
  contact += hasUpi   ?  5 : 0; if (!hasUpi)   missing.push("Add UPI ID (optional)");
  contact += hasAnyLink ? 10 : 0; if (!hasAnyLink) missing.push("Add any web/social link");

  // Rich (25)
  const hasLogo  = !!(p.homepage_image_url || "").trim();
  const hasVideo = !!(p.video_url || "").trim();
  const hasMap   = !!(p.google_map_link || "").trim();

  rich += hasLogo ? 10 : 0;  if (!hasLogo)  missing.push("Add logo/home image");
  rich += hasVideo ? 5 : 0;  if (!hasVideo) missing.push("Add video/brochure link");
  rich += hasMap ? 10 : 0;   if (!hasMap)   missing.push("Add Google Map link");

  // Trust (10)
  const isIndia = true;
  const hasGST  = !!(p.gstin || "").trim();
  if (isIndia) {
    trust += hasGST ? 5 : 0;
    if (!hasGST) missing.push("Add GSTIN");
  }
  const products = Array.isArray(p.products) ? p.products : [];
  const count = products.filter((q: any) => (q?.description || q?.mrp || q?.bestPrice)).length;
  trust += count >= 5 ? 5 : 0;
  if (count < 5) missing.push("Add more products (5+)");

  const total = core + contact + rich + trust;
  return {
    connector_type: "business",
    score_out_of_100: total,
    score_percent: total,
    core_points: core,
    contact_points: contact,
    rich_points: rich,
    trust_points: trust,
    products_count: count,
    missing_recommendations: Array.from(new Set(missing)),
  };
}


// Storage bucket (change if your bucket name differs)
const BUCKET =
  process.env.NEXT_PUBLIC_SUPABASE_BUSINESS_BUCKET || "business-images";

type Prod = { description: string; mrp: string; bestPrice: string };

// ── AA helpers ────────────────────────────────────────────────────────────────
const canon = (s: string) => String(s || "").trim().toLowerCase();

function padINTA(ref: string): string {
  const re = /(.*_INTA[A-Z]{2})(\d+)(.*)$/i;
  const m = (ref || "").trim().match(re);
  if (!m) return ref;
  const [_, head, digits, tail] = m;
  return `${head}${digits.padStart(9, "0")}${tail}`;
}


// Heuristic: adapt to your connector code shape. This just keeps your old ones working.
function looksLikeConnectorRef(ref: string) {
  const s = String(ref || "").trim();
  // Accept either:
  //  • strings that START with INT…  (legacy)
  //  • strings that CONTAIN an underscore/dash/space before INT… (e.g. "India_…_INTAAA000000001_G")
  //  • or contain keywords you've used historically
  return (
    /^INT[A-Z]/i.test(s) ||
    /(^|[_\s-])INT[A-Z]/i.test(s) ||   // <— key: matches “…_INTAA…”
    /CONNECTA/i.test(s) ||
    /CHPF/i.test(s)
  );
}


// Validates an AA code for the selected country/state and returns the AA region.
// • Accepts UPPERCASE column names too (we select "*").
// • State is enforced only when AA row is NOT "All States".
// • If duplicates exist, we DO NOT block: we pick the most specific row
//   (exact state match preferred; otherwise an "All States" row). If multiple
//   still tie, we pick the newest by created_at (or first).
async function resolveAAParentOrThrow(
  ref: string,
  selectedCountry: string,
  selectedState: string
): Promise<{ country: string; state: string; aaStateLock: boolean }> {
  const { data: rows, error: aaErr } = await supabase
  .from("aa_connectors")
  .select("*")
  .eq("aa_joining_code", ref);

if (aaErr) throw new Error(aaErr.message);

  if (!rows || rows.length === 0) {
    throw new Error("AA code not found");
  }

  // Normalize (and keep original row for deterministic tie-breaks)
  const records = rows.map((r: any) => ({
    row: r,
    country: String(r.country ?? r.COUNTRY ?? r.country_name ?? r.COUNTRY_NAME ?? "").trim(),
    state:   String(r.state   ?? r.STATE   ?? r.state_name   ?? r.STATE_NAME   ?? "").trim(),
  }));

  // 1) country must match
  const byCountry = records.filter((r) => canon(r.country) === canon(selectedCountry));
  if (byCountry.length === 0) {
    throw new Error("This AA code is not valid for the selected country.");
  }

  // 2) state: prefer exact match; otherwise allow "All States"
  const isAllStates = (s: string) =>
    canon(s).replace(/\s+/g, "") === "allstates" || s === "";

  const exactState = byCountry.filter((r) => canon(r.state) === canon(selectedState));
  const allStates  = byCountry.filter((r) => isAllStates(r.state));

  let pick: typeof records[number] | null = null;

  if (exactState.length > 0) {
    // Prefer newest by created_at if available
    exactState.sort((a, b) => {
      const ad = new Date(a.row?.created_at || 0).getTime();
      const bd = new Date(b.row?.created_at || 0).getTime();
      return bd - ad;
    });
    pick = exactState[0];
  } else if (allStates.length > 0) {
    allStates.sort((a, b) => {
      const ad = new Date(a.row?.created_at || 0).getTime();
      const bd = new Date(b.row?.created_at || 0).getTime();
      return bd - ad;
    });
    pick = allStates[0];
  } else {
    // No exact and no "All States"
    throw new Error("This AA code is not valid for the selected state.");
  }

  // Soft warning instead of blocking if multiple matched
  const totalMatches = exactState.length || allStates.length;
  if (totalMatches > 1) {
    console.warn(
      "[AA] Multiple rows matched aa_joining_code + region; proceeding with the most specific/newest."
    );
  }

  const aaCountry = pick.country || selectedCountry;
  const aaState   = pick.state   || selectedState;
  const lockState = !isAllStates(aaState);

  return {
    country: aaCountry,
    state: lockState ? aaState : selectedState,
    aaStateLock: lockState,
  };
}

// ── Field memory (local only) ────────────────────────────────────────────────
const MEM_NS = "bf_mem_v1";
const MAX_ITEMS = 15;

function loadMem(key: string): string[] {
  if (typeof window === "undefined") return [];
  try {
    const bag = JSON.parse(localStorage.getItem(MEM_NS) || "{}");
    const val = Array.isArray(bag[key]) ? bag[key] : [];
    return val.slice(0, MAX_ITEMS);
  } catch {
    return [];
  }
}
function saveMem(key: string, value: string) {
  if (typeof window === "undefined") return;
  const v = (value || "").trim();
  if (!v) return;
  try {
    const bag = JSON.parse(localStorage.getItem(MEM_NS) || "{}");
    const current: string[] = Array.isArray(bag[key]) ? bag[key] : [];
    const next = [v, ...current.filter((x) => x !== v)].slice(0, MAX_ITEMS);
    bag[key] = next;
    localStorage.setItem(MEM_NS, JSON.stringify(bag));
  } catch {}
}

/** Text input that remembers past values and offers them via <datalist>. */
function MemoryInput(
  props: React.InputHTMLAttributes<HTMLInputElement> & { memKey: string }
) {
  const { memKey, onBlur, onChange, list, ...rest } = props;
  const [options, setOptions] = useState<string[]>([]);
  const listId = list || `dl-${memKey}`;

  useEffect(() => {
    setOptions(loadMem(memKey));
  }, [memKey]);

  return (
    <>
      <input
        {...rest}
        list={listId}
        onBlur={(e) => {
          saveMem(memKey, (e.target as HTMLInputElement).value);
          onBlur?.(e);
        }}
        onChange={(e) => {
          onChange?.(e);
        }}
        autoComplete="off"
      />
      <datalist id={listId}>
        {options.map((opt) => (
          <option key={opt} value={opt} />
        ))}
      </datalist>
    </>
  );
}

function BusinessFormInner({ variant }: { variant: BusinessVariant }) {
  // App Router hook returns ReadonlyURLSearchParams in client components
  const sp = useSearchParams();
  const router = useRouter();
  const cfg = VARIANT_COPY[variant];
  const { i18n } = useTranslation();

  // URL params (string | null → coalesce to '')
  const mobileNumberFromURL = sp?.get('mobile') ?? '';

  // Read from Welcome
  const referralCode      = sp?.get('ref')            ?? '';
  const country           = sp?.get('country')        ?? '';
  const state             = sp?.get('state')          ?? '';
  const mobile            = sp?.get('mobile')         ?? ''; // E.164 from Welcome
  const recoveryMobile    = sp?.get('recoveryMobile') ?? ''; // E.164
  const langFromURL       = sp?.get('lang')           ?? '';
  const langLabelFromURL  = sp?.get('langLabel')      ?? '';
  const prefix            = sp?.get('prefix')         ?? ''; // e.g. +91



  // ⬇️ Language dropdown state (mirrors Connectors tab)
  const [selectedLanguage, setSelectedLanguage] = useState<string>("");
  const [languageOptions, setLanguageOptions] = useState<
    Array<{ code: string; display_name: string }>
  >([]);

  // One-time hydrate language from URL / LS / i18n
  useEffect(() => {
    const ls =
      typeof window !== "undefined"
        ? (localStorage.getItem("language") || "")
        : "";
    const current = (langFromURL || ls || i18n.language || "en")
      .toLowerCase()
      .replace("_", "-");
    setSelectedLanguage(current);
    try {
      i18n.changeLanguage(current);
    } catch {}
    if (typeof window !== "undefined")
      localStorage.setItem("language", current);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Fetch enabled languages once
useEffect(() => {
  (async () => {
    const { data, error: langsErr } = await supabase
      .from("languages")
      .select("code, display_name")
      .eq("enabled", true);

    if (!langsErr && data) {
      setLanguageOptions(
        data.map((l: any) => ({
          code: String(l.code).toLowerCase(),
          display_name: String(l.display_name || l.code),
        }))
      );
    } else if (langsErr) {
      console.warn("[languages] fetch failed:", langsErr.message);
    }
  })();
}, []);


  // Load translations + persist when language changes
  useEffect(() => {
    if (!selectedLanguage) return;
    (async () => {
      try {
        await supabase
          .from("translations")
          .select("translations")
          .eq("language_code", selectedLanguage)
          .maybeSingle();
      } catch {}
    })();
    try {
      i18n.changeLanguage(selectedLanguage);
    } catch {}
    if (typeof window !== "undefined")
      localStorage.setItem("language", selectedLanguage);
  }, [selectedLanguage, i18n]);

  // ── Complimentary subscription timing (optional UI+payload) ─────────────
  const joinedAtParam = sp?.get("joinedAt") ?? sp?.get("joined") ?? "";
  const joinedAt = useMemo<Date | null>(() => {
    if (!joinedAtParam) return new Date();
    const d = new Date(joinedAtParam);
    return isNaN(d.getTime()) ? new Date() : d;
  }, [joinedAtParam]);
  const expiresAt = useMemo<Date>(() => {
    const d = new Date(joinedAt!.getTime());
    d.setDate(d.getDate() + 365);
    return d;
  }, [joinedAt]);
  const daysLeft = useMemo<number>(() => {
    const ms = expiresAt.getTime() - Date.now();
    return Math.ceil(ms / (24 * 60 * 60 * 1000));
  }, [expiresAt]);
  const submitLocked = daysLeft <= 0;

  const showReminder =
    daysLeft <= 30 &&
    [30, 25, 20, 15, 10, 5, 4, 3, 2, 1].includes(Math.max(0, daysLeft));

  // Core fields
  const [gst, setGst] = useState("");
  const [company, setCompany] = useState("");
  const [shortCompany, setShortCompany] = useState("");
  const [classification, setClassification] = useState("SUPER MARKET");
  const [classificationOther, setClassificationOther] = useState("");
  const [addr1, setAddr1] = useState("");
  const [addr2, setAddr2] = useState("");
  const [addr3, setAddr3] = useState("");
  const [city, setCity] = useState("");
  const [pincode, setPincode] = useState("");
  const [email, setEmail] = useState("");

  // Media + links
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imageUrl, setImageUrl] = useState<string>("");
  const [website, setWebsite] = useState("");
  const [facebook, setFacebook] = useState("");
  const [instagram, setInstagram] = useState("");
  const [ytShorts, setYtShorts] = useState("");
  const [youtube, setYoutube] = useState("");
  const [linkOther, setLinkOther] = useState("");
  const [upiId, setUpiId] = useState("");
const [videoUrl, setVideoUrl] = useState("");
const [mapLink, setMapLink] = useState("");


  // Business text + discount
  const [offerings, setOfferings] = useState("");
  const [discountPct, setDiscountPct] = useState<string>("");

  // IE Code for import/export
  const [ieCode, setIeCode] = useState("");

  // Products array (max 50), reveal-on-fill for first 5
  const [products, setProducts] = useState<Prod[]>(
    Array.from({ length: 5 }, () => ({
      description: "",
      mrp: "",
      bestPrice: "",
    }))
  );

  // Grow rows on demand
  useEffect(() => {
    const last = products[products.length - 1];
    const filled = !!(
      last?.description?.trim() ||
      last?.mrp?.trim() ||
      last?.bestPrice?.trim()
    );
    if (filled && products.length < 50) {
      setProducts((prev) => [
        ...prev,
        { description: "", mrp: "", bestPrice: "" },
      ]);
    }
  }, [products]);

  // Upload image to Supabase Storage
  async function uploadImageIfAny(): Promise<string> {
    if (!imageFile) return "";
    const path = uniquePath(imageFile.name);

    const { error } = await supabase.storage
      .from(BUCKET)
      .upload(path, imageFile, {
        cacheControl: "3600",
        upsert: false,
        contentType: imageFile.type || "image/jpeg",
      });

    if (error) {
      alert(
        error.message.includes("Bucket not found")
          ? `Image upload failed: storage bucket "${BUCKET}" not found. Create it in Supabase Storage or update BUCKET in BusinessForm.tsx.`
          : "Image upload failed: " + error.message
      );
      return "";
    }
    const { data: pub } = supabase.storage.from(BUCKET).getPublicUrl(path);
    return pub?.publicUrl || "";
  }

  // ------- validation -------
  async function validateBasics(): Promise<boolean> {
    if (!company.trim()) return alert("Enter Name of the Company"), false;
if (!shortCompany.trim())
  return alert("Enter Short Company Name (≤ 14 chars)"), false;
if (shortCompany.trim().length > 14)
  return alert("Short Company Name must be ≤ 14 characters"), false;

    if (!classification.trim() && !classificationOther.trim())
      return alert("Select classification or type a new one"), false;
    if (!addr1.trim()) return alert("Address Line 1 is required"), false;
    if (!city.trim()) return alert("City/Town/Village is required"), false;
    if (!pincode.trim()) return alert("Pincode is required"), false;

    const isPinOK = await Promise.resolve(validatePincode(country, pincode));
    if (!isPinOK) {
      alert(`Invalid pincode format for ${country}`);
      return false;
    }

    if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      alert("Invalid email format");
      return false;
    }

    if (gst && country === "India" && !GSTIN_RE.test(gst.toUpperCase())) {
      alert("Invalid GST No. (India GSTIN 15 chars)");
      return false;
    }

    if (cfg.showIECode) {
      if (!ieCode.trim()) return alert("Enter IE Code"), false;
      if (country === "India" && !IEC_RE_NUM10.test(ieCode.trim())) {
        alert("Invalid IE Code (India: 10 digits)");
        return false;
      }
    }

// Auto-fix: add https:// for website if user typed a bare domain
if (website && !/^https?:\/\//i.test(website)) {
  setWebsite(withHttps(website));
}

const bad = [
  [website, "Website"],
  [facebook, "Facebook"],
  [instagram, "Instagram"],
  [ytShorts, "YouTube Shorts"],
  [youtube, "YouTube"],
  [linkOther, "Other Link"],
  [videoUrl, "Business Video URL"],
  [mapLink, "Google Maps Link"],
].find(([v]) => !isURL(String(v)));




    if (bad) {
      alert(`${bad[1]} URL looks invalid`);
      return false;
    }

    if (!offerings.trim()) {
      alert("Please describe your products/services offered");
      return false;
    }

    if (!discountPct.trim() || isNaN(Number(discountPct))) {
      alert("Enter Discount % as a number");
      return false;
    }

    if (submitLocked) {
      alert(
        "Your complimentary subscription has expired. Please renew to continue."
      );
      return false;
    }

    return true;
  }

  // 🔒 double-submit guard
  const submittingRef = useRef(false);

async function classifyCreatedConnector(row: any, params: {
  variant: BusinessVariant;
  shortName: string | null;
  fullName: string | null; // for business we pass null
}) {
  // Read identifiers from your RPC result safely (handles camel/snake)
  const createdId: string | null =
    row?.id ?? row?.connector_id ?? null;
  const createdConnectaId: string | null =
    row?.connecta_id ?? row?.connectaID ?? null;
  const createdReferral: string | null =
    row?.referral_code ?? row?.referralCode ?? null;

  const connectorTypeForDB: 'individual' | 'business' = 'business';
  const variantForDB: 'b2c' | 'b2b' | 'import' | 'export' = params.variant;

  const { error: classifyErr } = await supabase.rpc('classify_connector_v1', {
    p_id: createdId,
    p_connecta_id: createdConnectaId,
    p_referral_code: createdReferral,
    p_connector_type: connectorTypeForDB,
    p_business_variant: variantForDB,
    p_short_name: params.shortName,
    p_full_name: params.fullName, // for business, keep null so we don't touch full_name
  });

  if (classifyErr) {
    console.warn('classify_connector_v1 failed:', classifyErr.message);
    // Non-fatal: we still continue navigation.
  }
}

  const headerNote = useMemo(() => cfg.sub, [cfg.sub]);


// ------- submit -------
async function handleSubmit() {
  if (submittingRef.current) return;
  submittingRef.current = true;

  try {
    if (!(await validateBasics())) return;

    // 0) Duplicate guard BEFORE calling the RPC
    try {
      const e164 = normalizePhone(mobile);
      let exists = false;
      let existingRef: string | null = null;

      // Preferred: your RPC if present
      const { data: existsData, error: existsErr } = await supabase
        .rpc("connector_exists_normalized", { p_mobile: e164 });

      if (existsErr) {
        // fallback read
        const { data: rows, error: readErr } = await supabase
          .from("connectors")
          .select("referralCode")
          .eq("mobile_number", e164)
          .limit(1);

        if (!readErr && rows?.length) {
          exists = true;
          existingRef = rows[0]?.referralCode ?? null;
        }
      } else {
        exists = !!existsData;
        if (exists) {
          const { data: rows } = await supabase
            .from("connectors")
            .select("referralCode")
            .eq("mobile_number", e164)
            .limit(1);
          existingRef = rows?.[0]?.referralCode ?? null;
        }
      }

if (exists) {
  // 🔄 gently upsert minimal metadata (non-blocking)
  const { error: upsertErr } = await supabase.rpc("upsert_connector_by_mobile_number", {
    p_mobile_number: e164,
    p_full_name: company || null,
    p_country: country || null,
    p_state: state || null,
    p_language: selectedLanguage || langFromURL || null,
    p_referral_code: null,
  });
  if (upsertErr) console.warn("[upsert pre-RPC] non-fatal:", upsertErr.message);

  alert("This mobile number is already registered as a connector.");

  // 👉 Single source of truth: fetch the existing global_connecta_id and pass it to Post-Join
  if (existingRef) {
    let gid = "";
    try {
      const { data: existingRow } = await supabase
        .from("connectors")
        .select("global_connecta_id")
        .eq("referralCode", existingRef)
        .maybeSingle();
      gid = existingRow?.global_connecta_id || "";
    } catch {}

    const params = new URLSearchParams({
      ref: existingRef,
      country: country || "",
      state: state || "",
      mobile: mobile || "",
      recovery: recoveryMobile || "",
      prefix: prefix || "",
      connectaId: gid || "", // 👈 pass computed ID from DB
    });
    router.replace(`/post-join?${params.toString()}`);
  }

  submittingRef.current = false;
  return;
}


    } catch (dupErr) {
      console.warn("[dup-guard] non-fatal:", dupErr);
    }

    // 1) Upload image first
    const uploadedUrl = await uploadImageIfAny();
    if (uploadedUrl) setImageUrl(uploadedUrl);
// ------------------------------------------------------------------
// 2) Parent resolution (AA vs connector) — region-safe + All-States aware
// ------------------------------------------------------------------
const connectorType = CONNECTOR_TYPES[cfg.connectorType];

// Defaults from URL (may be narrowed by AA row)
let finalCountry = country;
let finalState = state;

// For the RPC we pass ONLY a connector referralCode (or null).
let parentRefForRPC: string | null = null; // connector referralCode or null
let p_child_branch: string | null = null; // let RPC decide

const refTrim = padINTA((referralCode || "").trim());

if (refTrim) {
  if (looksLikeConnectorRef(refTrim)) {
    // Connector parent → pass the referralCode; FE must tell RPC the child branch
    parentRefForRPC = refTrim;
    p_child_branch = "B"; // tell RPC this is a child branch
  } else {
    // AA joining code → narrow region only (do NOT pass as parent)
    try {
      const aa = await resolveAAParentOrThrow(refTrim, country, state);
      finalCountry = aa.country;
      finalState = aa.state;
      parentRefForRPC = null; // root insert (new AA)
      p_child_branch = null; // RPC derives 'AA' for root
    } catch (e: any) {
      alert(e?.message || "Invalid AA referral for the selected region.");
      return;
    }
  }
}

console.log("[parent resolution]", {
  finalCountry,
  finalState,
  parentRefForRPC,
  p_child_branch,
});

// --- DIAGNOSTIC LOGS ONLY — NO LOGIC CHANGE ---

    try {
      // connectors table (use actual columns in your schema)
      const c1 = await supabase
        .from("connectors")
        .select("id, referralCode, level, level_sequence")
        .eq("mobile_number", normalizePhone(mobile))
        .limit(1)
        .maybeSingle();
      console.log("[dup-check] connectors:", c1);

      // aa_connectors table (quote UPPER-CASE cols)
      const a1 = await supabase
        .from("aa_connectors")
        .select('id, aa_joining_code, "COUNTRY", "STATE", "LANGUAGE", mobile')
        .eq("mobile", normalizePhone(mobile))
        .maybeSingle();
      console.log("[dup-check] aa_connectors:", a1);

      console.log("[referral] raw ref from URL =", referralCode);
      console.log(
        "[referral] value currently passed as parent_ref =",
        parentRefForRPC
      );
    } catch (diagErr) {
      console.warn("[diag] query error (non-fatal):", diagErr);
    }
    // --- END DIAGNOSTICS ---
// --- keep your existing p_payload as-is (it gets stored in payload_json) ---
// --- Step 7 hygiene: normalize before building payload ---
const websiteNorm = withHttps(website || "");
// --- normalized p_payload (stored in payload_json) ---
const emailNorm = normalizeEmail(email);
const upiNorm = normalizeUpi(upiId);
const productsClean = sanitizeProducts(
  products.filter((p) => p.description || p.mrp || p.bestPrice).slice(0, 50)
);

const p_payload: any = {
  language: (selectedLanguage || langFromURL || "").toLowerCase().replace("_", "-"),
  company: company,
  shortCompany,
  classification: classificationOther?.trim()
    ? `PENDING:${classificationOther.trim()}`
    : classification,
  addressLine1: addr1,
  addressLine2: addr2,
  addressLine3: addr3,
  city,
  pincode,
  email: emailNorm || "",
  connector_type: String(connectorType),
  subtype: cfg.subtype || undefined,
  gstin: gst || undefined,
  homepage_image_url: uploadedUrl || undefined,
  upi_id: upiNorm || undefined,
  video_url: videoUrl || undefined,
  google_map_link: mapLink || undefined,
  links: {
    website: withHttps(website || ""),
    facebook,
    instagram,
    ytShorts,
    youtube,
    other: linkOther,
  },
  offerings,
  discount_percent: Number.isFinite(Number(discountPct)) ? Number(discountPct) : null,
  ie_code: cfg.showIECode ? ieCode : undefined,
  pricing_copy: cfg.sub,
  subscription_joined_at: joinedAt?.toISOString(),
  subscription_expires_at: expiresAt.toISOString(),
  products: productsClean,
};

const scorePreview = scoreBusinessPayload(p_payload);
console.log("[profile-score/preview]", scorePreview);
// Optional: attach for diagnostics (not persisted/relied upon server-side)
(p_payload as any).__score_preview = scorePreview;



// --- NEW wrapper for v3 (single, correct call) ---
const rpcArgs = {
  p_country: finalCountry,
  p_state: finalState,
  p_parent_ref: parentRefForRPC,                    // connector referral or null
  p_mobile: normalizePhone(mobileNumberFromURL || mobile),
  p_fullname: "",                                   // business flow: keep empty
  p_email: email || "",
  p_extra: { suffix: (shortCompany || company).slice(0, 10) },
  p_recovery_e164: recoveryMobile ? normalizePhone(recoveryMobile) : null,
  p_payload,                                        // everything else into payload_json
};

console.log("[RPC v3 payload]", rpcArgs);

let v3Data: any = null, v3Err: any = null;
try {
  const { data, error } = await supabase.rpc("generate_and_insert_connector_v3", rpcArgs);
  v3Data = data;
  v3Err = error;
} catch (e: any) {
  alert(e?.message || String(e));
  return;
}

if (v3Err) {
  console.group("[RPC error] generate_and_insert_connector_v3");
  console.log("code   :", v3Err.code);
  console.log("message:", v3Err.message);
  console.log("details:", v3Err.details);
  console.log("hint   :", v3Err.hint);
  console.groupEnd();
  alert(`Supabase insert error: ${v3Err.message}`);
  return;
}

const row = Array.isArray(v3Data) ? v3Data[0] : v3Data;
const connectorId: string | null = row?.id ?? row?.connector_id ?? null;
const newReferralCode: string | null = row?.referral_code ?? row?.referralCode ?? null;

if (newReferralCode) {
  console.log("✅ New referral code:", newReferralCode);
}

await classifyCreatedConnector(row, {
  variant,
  shortName: deriveShortName(company, shortCompany) || null, // ✅ up to 14 chars
  fullName: null, // business flow: do not touch full_name
});


// --- Single source of truth: global_connecta_id from DB ---
let globalId: string =
  (row?.global_connecta_id && String(row.global_connecta_id)) || "";

if (!globalId && connectorId) {
  const { data: g, error: gErr } = await supabase
    .from("connectors")
    .select("global_connecta_id")
    .eq("id", connectorId)
    .maybeSingle();
  if (!gErr) globalId = g?.global_connecta_id || "";
}

// (Optional) If you later need them: row.connectaID, row.connectaID_full, row.level, row.serial, row.country, row.state

// Record custom classification once (no duplicates)
if (classification === "OTHER" && classificationOther.trim() && connectorId) {
  const { error: pendErr } = await supabase
    .from("pending_classifications")
    .insert({
      name: classificationOther.trim(),
      suggested_by_connector_id: connectorId,
      country: finalCountry,
      state: finalState,
      variant,
      status: "pending",
      created_at: new Date().toISOString(),
    });
  if (pendErr) console.warn("pending_classifications insert error:", pendErr.message);
}

// Navigate to /post-join with the **global** ID
const refForSuccess = String(newReferralCode || parentRefForRPC || referralCode || "");

const qs = new URLSearchParams({
  ref: refForSuccess,
  country: finalCountry || "",
  state: finalState || "",
  mobile: mobile || "",
  recovery: recoveryMobile || "",
  prefix: prefix || "",
  connectaId: globalId || "", // 👈 the only ID the Post-Join should display
});

console.debug("[navigate] → /post-join?" + qs.toString());
router.replace(`/post-join?${qs.toString()}`);
return;


    } catch (err: any) {
      console.error("[handleSubmit] fatal:", err);
      alert("Unexpected error during submission. Please try again.");
    } finally {
      submittingRef.current = false;
    }
  } // end handleSubmit

  return (

    <div className="min-h-screen bg-white text-black px-4 py-6">
      <div className="max-w-2xl mx-auto">
        <h1 className="text-2xl font-bold text-blue-700">{cfg.title}</h1>
        <p className="text-sm text-gray-700 mb-2">{headerNote}</p>

        {/* Complimentary subscription banner */}
        <div className="mb-4 rounded-md border border-amber-300 bg-amber-50 text-amber-900 px-3 py-2 leading-tight">
          <div className="text-xs">
            <span className="font-semibold">Complimentary subscription</span>{" "}
            valid until{" "}
            <span className="font-mono font-semibold">
              {expiresAt.toDateString()}
            </span>
            
            {showReminder && daysLeft > 0 && (
              <span className="ml-2 font-semibold">
                {daysLeft} day{daysLeft === 1 ? "" : "s"} left.
              </span>
            )}
            {daysLeft <= 0 && (
              <span className="ml-2 font-semibold text-red-700">
                Expired — submissions disabled.
              </span>
            )}
          </div>
        </div>

        {/* Language selector (editable) */}
        <div className="mb-3">
          <label className="text-sm font-semibold">Select Language</label>
          <select
            value={selectedLanguage}
            onChange={(e) =>
              setSelectedLanguage(
                (e.target.value || "").toLowerCase().replace("_", "-")
              )
            }
            className="border p-2 rounded-md w-full bg-white text-black focus:outline-none focus:ring-2 focus:ring-blue-500 truncate"
          >
            {(selectedLanguage || langFromURL) &&
              !(languageOptions || []).some(
                (l) =>
                  l.code ===
                  String(selectedLanguage || langFromURL).toLowerCase()
              ) && (
                <option value={selectedLanguage || langFromURL}>
                  {langLabelFromURL ||
                    String(selectedLanguage || langFromURL).toUpperCase()}
                </option>
              )}
            <option value="">Select language</option>
            {(languageOptions || []).map((l) => (
              <option key={l.code} value={l.code}>
                {(l.display_name || l.code) +
                  " — " +
                  String(l.code).toUpperCase()}
              </option>
            ))}
          </select>
        </div>

        {/* Shared read-only summaries (phones + region/language) */}
        <PhoneSummary
          primary={mobile}
          recovery={recoveryMobile}
          className="border-blue-200 bg-blue-50 text-blue-900"
        />
        <RegionLangSummary
          language={
            langLabelFromURL ||
            (selectedLanguage ? selectedLanguage.toUpperCase() : "")
          }
          country={country}
          state={state}
          className="border-blue-200 bg-blue-50 text-blue-900"
        />

        {/* Company */}
        <div className="grid gap-3 mt-4">
          <div>
            <label className="text-sm font-semibold">GST No (optional)</label>
            <input
              value={gst}
              onChange={(e) => setGst(e.target.value)}
              className="border p-2 rounded-md w-full"
              placeholder="e.g., 22AAAAA0000A1Z5"
            />
          </div>
          <div>
            <label className="text-sm font-semibold">Name of the Company *</label>
            <input
              value={company}
              onChange={(e) => setCompany(e.target.value)}
              className="border p-2 rounded-md w-full"
            />
          </div>
          <div>
            <label className="text-sm font-semibold">
  Short Company Name (≤ 14 chars) *
</label>
<input
  value={shortCompany}
  onChange={(e) => setShortCompany(e.target.value.slice(0, 14))}
  className="border p-2 rounded-md w-full"
/>

          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            <div>
              <label className="text-sm font-semibold">Classification *</label>
              <select
                value={classification}
                onChange={(e) => setClassification(e.target.value)}
                className="border p-2 rounded-md w-full"
              >
                {CLASSIFICATIONS_IN.map((c) => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
              </select>
            </div>
            {classification === "OTHER" && (
              <div>
                <label className="text-sm font-semibold">
                  If your category is not available, add here
                </label>
                <input
                  value={classificationOther}
                  onChange={(e) => setClassificationOther(e.target.value)}
                  className="border p-2 rounded-md w-full"
                  placeholder="Pending admin validation"
                />
              </div>
            )}
          </div>

          {/* Address */}
          <div className="grid grid-cols-1 gap-3">
            <div>
              <label className="text-sm font-semibold">Address Line - 1 *</label>
              <input
                value={addr1}
                onChange={(e) => setAddr1(e.target.value)}
                className="border p-2 rounded-md w-full"
              />
            </div>
            <div>
              <label className="text-sm font-semibold">Address Line - 2</label>
              <input
                value={addr2}
                onChange={(e) => setAddr2(e.target.value)}
                className="border p-2 rounded-md w-full"
              />
            </div>
            <div>
              <label className="text-sm font-semibold">Address Line - 3</label>
              <input
                value={addr3}
                onChange={(e) => setAddr3(e.target.value)}
                className="border p-2 rounded-md w-full"
              />
            </div>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
              <div className="md:col-span-1">
                <label className="text-sm font-semibold">
                  City/Town/Village *
                </label>
                <input
                  value={city}
                  onChange={(e) => setCity(e.target.value)}
                  className="border p-2 rounded-md w-full"
                />
              </div>
              <div className="md:col-span-1">
                <label className="text-sm font-semibold">Pincode *</label>
                <input
                  value={pincode}
                  onChange={(e) => setPincode(e.target.value)}
                  className="border p-2 rounded-md w-full"
                />
              </div>
              <div className="md:col-span-1">
                <label className="text-sm font-semibold">Email</label>
                <input
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="border p-2 rounded-md w-full"
                />
              </div>
            </div>
          </div>

          {/* Image upload */}
          <div>
            <label className="text-sm font-semibold block">
              Home Page Image of the Business
            </label>
            <input
              type="file"
              accept="image/*"
              onChange={(e) => setImageFile(e.target.files?.[0] || null)}
              className="mt-1"
            />
          </div>

          {/* Links */}
          <div className="grid grid-cols-1 gap-3">
            <div>
              <label className="text-sm font-semibold">Website URL</label>
              <input
                value={website}
                onChange={(e) => setWebsite(e.target.value)}
                className="border p-2 rounded-md w-full"
                placeholder="https://example.com"
              />
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div>
                <label className="text-sm font-semibold">Facebook</label>
                <input
                  value={facebook}
                  onChange={(e) => setFacebook(e.target.value)}
                  className="border p-2 rounded-md w-full"
                />
              </div>
              <div>
                <label className="text-sm font-semibold">Instagram</label>
                <input
                  value={instagram}
                  onChange={(e) => setInstagram(e.target.value)}
                  className="border p-2 rounded-md w-full"
                />
              </div>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div>
                <label className="text-sm font-semibold">YouTube Shorts</label>
                <input
                  value={ytShorts}
                  onChange={(e) => setYtShorts(e.target.value)}
                  className="border p-2 rounded-md w-full"
                />
              </div>
              <div>
                <label className="text-sm font-semibold">YouTube</label>
                <input
                  value={youtube}
                  onChange={(e) => setYoutube(e.target.value)}
                  className="border p-2 rounded-md w-full"
                />
              </div>
            </div>
            <div>
              <label className="text-sm font-semibold">Others</label>
              <input
                value={linkOther}
                onChange={(e) => setLinkOther(e.target.value)}
                className="border p-2 rounded-md w-full"
              />
            </div>
          </div>

          {/* Offerings + Discount */}
          <div>
            <label className="text-sm font-semibold">
              Products and Services Offered *
            </label>
            <textarea
              value={offerings}
              onChange={(e) => setOfferings(e.target.value)}
              className="border p-2 rounded-md w-full h-24"
            />
          </div>
          <div>
            <label className="text-sm font-semibold">Discount % *</label>
            <input
              value={discountPct}
              onChange={(e) => setDiscountPct(e.target.value)}
              className="border p-2 rounded-md w-40"
              placeholder="e.g. 5"
            />
            <p className="text-xs text-gray-600 mt-1">
              This % will be used to calculate commission & split.
            </p>
          </div>
          {/* UPI ID */}
<div>
  <label className="text-sm font-semibold">UPI ID</label>
  <input
    value={upiId}
    onChange={(e) => setUpiId(e.target.value)}
    className="border p-2 rounded-md w-full"
    placeholder="e.g., acme@upi"
  />
</div>

{/* Promo / Intro Video URL */}
<div>
  <label className="text-sm font-semibold">Business Video URL</label>
  <input
    value={videoUrl}
    onChange={(e) => setVideoUrl(e.target.value)}
    className="border p-2 rounded-md w-full"
    placeholder="https://…"
  />
</div>

{/* Google Maps link */}
<div>
  <label className="text-sm font-semibold">Google Maps Link</label>
  <input
    value={mapLink}
    onChange={(e) => setMapLink(e.target.value)}
    className="border p-2 rounded-md w-full"
    placeholder="https://maps.google.com/?q=…"
  />
</div>


          {/* IE Code (import/export) */}
          {cfg.showIECode && (
            <div>
              <label className="text-sm font-semibold">IE Code *</label>
              <input
                value={ieCode}
                onChange={(e) => setIeCode(e.target.value)}
                className="border p-2 rounded-md w-full"
                placeholder={
                  country === "India" ? "10-digit IEC" : "Enter IE/Exporter Code"
                }
              />
            </div>
          )}

          {/* Products table-like inputs */}
          <div className="mt-4">
            <div className="text-sm font-semibold mb-2">
              Products (up to 50)
            </div>
            <div className="space-y-2">
              {products.map((p, i) => (
                <div
                  key={i}
                  className="grid grid-cols-1 md:grid-cols-6 gap-2 items-center"
                >
                  <div className="md:col-span-3">
                    <input
                      value={p.description}
                      onChange={(e) => {
                        const v = e.target.value;
                        setProducts((prev) =>
                          prev.map((row, idx) =>
                            idx === i ? { ...row, description: v } : row
                          )
                        );
                      }}
                      className="border p-2 rounded-md w-full"
                      placeholder={`Product ${i + 1} — up to ~100 words`}
                    />
                  </div>
                  <div className="md:col-span-1">
                    <input
                      value={p.mrp}
                      onChange={(e) => {
                        const v = e.target.value.replace(/[^0-9.]/g, "");
                        setProducts((prev) =>
                          prev.map((row, idx) =>
                            idx === i ? { ...row, mrp: v } : row
                          )
                        );
                      }}
                      className="border p-2 rounded-md w-full"
                      placeholder="MRP"
                    />
                  </div>
                  <div className="md:col-span-1">
                    <input
                      value={p.bestPrice}
                      onChange={(e) => {
                        const v = e.target.value.replace(/[^0-9.]/g, "");
                        setProducts((prev) =>
                          prev.map((row, idx) =>
                            idx === i ? { ...row, bestPrice: v } : row
                          )
                        );
                      }}
                      className="border p-2 rounded-md w-full"
                      placeholder="Best Price"
                    />
                  </div>
                  <div className="md:col-span-1 text-xs text-gray-600">
                    {p.mrp &&
                    p.bestPrice &&
                    !isNaN(Number(p.mrp)) &&
                    !isNaN(Number(p.bestPrice)) ? (
                      <span>
                        Save{" "}
                        {Math.max(
                          0,
                          Number(p.mrp) - Number(p.bestPrice)
                        ).toFixed(2)}
                      </span>
                    ) : (
                      <span>&nbsp;</span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="mt-6">
            <button
             type="button"
              onClick={handleSubmit}
              disabled={submitLocked}
              className={`py-2 px-4 rounded-md text-white ${
                submitLocked
                  ? "bg-gray-400 cursor-not-allowed"
                  : "bg-blue-600 hover:bg-blue-700"
              }`}
              title={
                submitLocked ? "Subscription expired — renew to continue" : ""
              }
            >
              Submit Details
            </button>
          </div>
        </div>
      </div>
        </div>
  );
}

// --- Suspense wrapper (fixes useSearchParams CSR bailout) ---
export default function BusinessForm(props: { variant: BusinessVariant }) {
  return (
    <Suspense fallback={<div className="p-4 text-sm text-gray-600">Loading…</div>}>
      <BusinessFormInner {...props} />
    </Suspense>
  );
}
