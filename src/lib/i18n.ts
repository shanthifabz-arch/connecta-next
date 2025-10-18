import i18n from "i18next";
import { initReactI18next } from "react-i18next";

// very small in-memory English fallback; your component later loads DB bundles
const FALLBACK = {
  translation: {
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
    accept_terms: "I accept the",
    terms_and_conditions: "Terms & Conditions",
    alert: { accept_terms: "Please accept the terms and conditions." },
  },
};

// Initialize once; subsequent imports are no-ops
if (!i18n.isInitialized) {
  i18n
    .use(initReactI18next)
    .init({
      resources: { en: FALLBACK },
      lng: "en",
      fallbackLng: "en",
      interpolation: { escapeValue: false },
      react: { useSuspense: false },
      returnNull: false,
    })
    .catch(() => {
      /* swallow init errors during dev */
    });
}

export default i18n;
