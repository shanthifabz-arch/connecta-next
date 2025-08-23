"use client";

import { useSearchParams } from "next/navigation";
import { useState, useRef, useEffect } from "react";
import html2canvas from "html2canvas";
import { QRCode } from "react-qrcode-logo";
import { useCountryStateOptions } from "@/hooks/useCountryStateOptions";
import { supabase } from "@/lib/supabaseClient";

const countryCodeMap: { [key: string]: string } = {
  "Afghanistan": "+93",
  "Albania": "+355",
  "Algeria": "+213",
  "American Samoa": "+1-684",
  "Andorra": "+376",
  "Angola": "+244",
  "Anguilla": "+1-264",
  "Antigua and Barbuda": "+1-268",
  "Argentina": "+54",
  "Armenia": "+374",
  "Aruba": "+297",
  "Australia": "+61",
  "Austria": "+43",
  "Azerbaijan": "+994",
  "Bahamas": "+1-242",
  "Bahrain": "+973",
  "Bangladesh": "+880",
  "Barbados": "+1-246",
  "Belarus": "+375",
  "Belgium": "+32",
  "Belize": "+501",
  "Benin": "+229",
  "Bermuda": "+1-441",
  "Bhutan": "+975",
  "Bolivia": "+591",
  "Bosnia and Herzegovina": "+387",
  "Botswana": "+267",
  "Brazil": "+55",
  "British Virgin Islands": "+1-284",
  "Brunei": "+673",
  "Bulgaria": "+359",
  "Burkina Faso": "+226",
  "Burundi": "+257",
  "Cabo Verde": "+238",
  "Cambodia": "+855",
  "Cameroon": "+237",
  "Canada": "+1",
  "Caribbean Netherlands": "+599",
  "Cayman Islands": "+1-345",
  "Central African Republic": "+236",
  "Chad": "+235",
  "Chile": "+56",
  "China": "+86",
  "Colombia": "+57",
  "Comoros": "+269",
  "Congo": "+242",
  "Cook Islands": "+682",
  "Costa Rica": "+506",
  "CÃ´te d'Ivoire": "+225",
  "Croatia": "+385",
  "Cuba": "+53",
  "CuraÃ§ao": "+599",
  "Cyprus": "+357",
  "Czech Republic (Czechia)": "+420",
  "Denmark": "+45",
  "Djibouti": "+253",
  "Dominica": "+1-767",
  "Dominican Republic": "+1-809",
  "DR Congo": "+243",
  "Ecuador": "+593",
  "Egypt": "+20",
  "El Salvador": "+503",
  "Equatorial Guinea": "+240",
  "Eritrea": "+291",
  "Estonia": "+372",
  "Eswatini": "+268",
  "Ethiopia": "+251",
  "Faeroe Islands": "+298",
  "Falkland Islands": "+500",
  "Fiji": "+679",
  "Finland": "+358",
  "France": "+33",
  "French Guiana": "+594",
  "French Polynesia": "+689",
  "Gabon": "+241",
  "Gambia": "+220",
  "Georgia": "+995",
  "Germany": "+49",
  "Ghana": "+233",
  "Gibraltar": "+350",
  "Greece": "+30",
  "Greenland": "+299",
  "Grenada": "+1-473",
  "Guadeloupe": "+590",
  "Guam": "+1-671",
  "Guatemala": "+502",
  "Guinea": "+224",
  "Guinea-Bissau": "+245",
  "Guyana": "+592",
  "Haiti": "+509",
  "Holy See": "+379",
  "Honduras": "+504",
  "Hong Kong": "+852",
  "Hungary": "+36",
  "Iceland": "+354",
  "India": "+91",
  "Indonesia": "+62",
  "Iran": "+98",
  "Iraq": "+964",
  "Ireland": "+353",
  "Isle of Man": "+44-1624",
  "Israel": "+972",
  "Italy": "+39",
  "Jamaica": "+1-876",
  "Japan": "+81",
  "Jordan": "+962",
  "Kazakhstan": "+7",
  "Kenya": "+254",
  "Kiribati": "+686",
  "Kuwait": "+965",
  "Kyrgyzstan": "+996",
  "Laos": "+856",
  "Latvia": "+371",
  "Lebanon": "+961",
  "Lesotho": "+266",
  "Liberia": "+231",
  "Libya": "+218",
  "Liechtenstein": "+423",
  "Lithuania": "+370",
  "Luxembourg": "+352",
  "Macao": "+853",
  "Madagascar": "+261",
  "Malawi": "+265",
  "Malaysia": "+60",
  "Maldives": "+960",
  "Mali": "+223",
  "Malta": "+356",
  "Marshall Islands": "+692",
  "Martinique": "+596",
  "Mauritania": "+222",
  "Mauritius": "+230",
  "Mayotte": "+262",
  "Mexico": "+52",
  "Micronesia": "+691",
  "Moldova": "+373",
  "Monaco": "+377",
  "Mongolia": "+976",
  "Montenegro": "+382",
  "Montserrat": "+1-664",
  "Morocco": "+212",
  "Mozambique": "+258",
  "Myanmar": "+95",
  "Namibia": "+264",
  "Nauru": "+674",
  "Nepal": "+977",
  "Netherlands": "+31",
  "New Caledonia": "+687",
  "New Zealand": "+64",
  "Nicaragua": "+505",
  "Niger": "+227",
  "Nigeria": "+234",
  "Niue": "+683",
  "North Korea": "+850",
  "North Macedonia": "+389",
  "Northern Mariana Islands": "+1-670",
  "Norway": "+47",
  "Oman": "+968",
  "Pakistan": "+92",
  "Palau": "+680",
  "Panama": "+507",
  "Papua New Guinea": "+675",
  "Paraguay": "+595",
  "Peru": "+51",
  "Philippines": "+63",
  "Poland": "+48",
  "Portugal": "+351",
  "Qatar": "+974",
  "RÃ©union": "+262",
  "Romania": "+40",
  "Russia": "+7",
  "Rwanda": "+250",
  "Saint BarthÃ©lemy": "+590",
  "Saint Helena": "+290",
  "Saint Kitts & Nevis": "+1-869",
  "Saint Lucia": "+1-758",
  "Saint Pierre & Miquelon": "+508",
  "Samoa": "+685",
  "San Marino": "+378",
  "Sao Tome & Principe": "+239",
  "Saudi Arabia": "+966",
  "Senegal": "+221",
  "Serbia": "+381",
  "Seychelles": "+248",
  "Sierra Leone": "+232",
  "Singapore": "+65",
  "Sint Maarten": "+1-721",
  "Slovakia": "+421",
  "Slovenia": "+386",
  "Solomon Islands": "+677",
  "Somalia": "+252",
  "South Africa": "+27",
  "South Korea": "+82",
  "South Sudan": "+211",
  "Spain": "+34",
  "Sri Lanka": "+94",
  "St. Vincent & Grenadines": "+1-784",
  "State of Palestine": "+970",
  "Sudan": "+249",
  "Suriname": "+597",
  "Sweden": "+46",
  "Switzerland": "+41",
  "Syria": "+963",
  "Taiwan": "+886",
  "Tajikistan": "+992",
  "Tanzania": "+255",
  "Thailand": "+66",
  "Timor-Leste": "+670",
  "Togo": "+228",
  "Tokelau": "+690",
  "Tonga": "+676",
  "Trinidad and Tobago": "+1-868",
  "Tunisia": "+216",
  "Turkey": "+90",
  "Turkmenistan": "+993",
  "Turks and Caicos": "+1-649",
  "Tuvalu": "+688",
  "U.S. Virgin Islands": "+1-340",
  "Uganda": "+256",
  "Ukraine": "+380",
  "United Arab Emirates": "+971",
  "United Kingdom": "+44",
  "Uruguay": "+598",
  "USA": "+1",
  "Uzbekistan": "+998",
  "Vanuatu": "+678",
  "Venezuela": "+58",
  "Vietnam": "+84",
  "Wallis & Futuna": "+681",
  "Western Sahara": "+212",
  "Yemen": "+967",
  "Zambia": "+260",
  "Zimbabwe": "+263"
};

export default function OnboardingTabs() {
  const searchParams = useSearchParams();
  const referralCode = searchParams.get("ref") || "";

  const [activeTab, setActiveTab] = useState("individual");
  const [connectaID, setConnectaID] = useState("");
  const [submitted, setSubmitted] = useState(false);
  const [profileImage, setProfileImage] = useState<File | null>(null);
  const [contactsAllowed, setContactsAllowed] = useState(false);
  const [selectedContacts, setSelectedContacts] = useState<{ name: string; mobile: string }[]>([]);
  const [qrSent, setQrSent] = useState(false);
  const qrRef = useRef(null);

  const [formData, setFormData] = useState({
    fullName: "",
    profession: "",
    mobile: "+91",
    addressLine1: "",
    addressLine2: "",
    addressLine3: "",
    city: "",
    pincode: "",
    country: "India",
    state: "Tamil Nadu",
    email: "",
    recoveryMobile: ""
  });

  const { countries, statesByCountry } = useCountryStateOptions();
  const states = statesByCountry[formData.country] || [];

  useEffect(() => {
    if (!connectaID) {
      setConnectaID("IN" + Date.now());
    }
  }, [connectaID]);

  const validateMobile = (mobile: string) => /^\+\d{10,15}$/.test(mobile);

  const handleChange = (e: any) => {
    const { name, value } = e.target;

    if (name === "country") {
      const code = countryCodeMap[value] || "";
      setFormData(prev => ({
        ...prev,
        country: value,
        mobile: code,
        state: ""
      }));
      return;
    }

    if (name === "mobile") {
      const code = countryCodeMap[formData.country] || "";
      if (!value.startsWith(code)) {
        setFormData(prev => ({ ...prev, mobile: code }));
      } else {
        setFormData(prev => ({ ...prev, mobile: value }));
      }
      return;
    }

    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async () => {
    if (!formData.fullName) return alert("Full Name is required.");
    if (!validateMobile(formData.mobile)) return alert("Invalid Mobile Number.");
    if (!formData.country) return alert("Please select a Country.");
    if (!formData.state) return alert("Please select a State.");
    if (!formData.city || !formData.pincode) return alert("Enter City and Pincode.");

    try {
      const { data, error } = await supabase.from("connectors").insert([{
        connectaID,
        referralCode,
        ...formData,
        createdAt: new Date().toISOString()
      }]);

      if (error) {
        console.error("âŒ Supabase insert error:", error);
        alert("Supabase insert error: " + error.message);
      } else {
        console.log("âœ… Supabase insert success:", data);
        setSubmitted(true);
      }
    } catch (err) {
      console.error("âŒ Unexpected error:", err);
      alert("Unexpected error occurred.");
    }
  };

  const handleProfileImage = (e: any) => {
    const file = e.target.files?.[0];
    if (file) setProfileImage(file);
  };

  const handleAllowContacts = () => {
    const allow = window.confirm("Allow CONNECTA to access your contacts?");
    if (allow) {
      setContactsAllowed(true);
      setSelectedContacts([
        { name: "Arun", mobile: "9876543210" },
        { name: "Divya", mobile: "9876543211" },
        { name: "Ravi", mobile: "9876543212" },
        { name: "Sneha", mobile: "9876543213" },
        { name: "Kumar", mobile: "9876543214" }
      ]);
    }
  };

  const handleSendQR = () => setQrSent(true);

  const downloadQR = async () => {
    if (!qrRef.current) return;
    const canvas = await html2canvas(qrRef.current);
    const link = document.createElement("a");
    link.download = "connecta_qr.png";
    link.href = canvas.toDataURL();
    link.click();
  };

  const downloadReferralLink = () => {
    const blob = new Blob([
      `CONNECTA Referral Link: https://connecta.co.in/join?ref=${connectaID}`
    ], { type: "text/plain" });
    const link = document.createElement("a");
    link.download = "referral_link.txt";
    link.href = URL.createObjectURL(blob);
    link.click();
  };

  return (
    <div className="min-h-screen bg-white flex flex-col items-center p-4">
      <h1 className="text-2xl font-bold text-blue-700 mb-4">CONNECTA â€" Onboarding</h1>

      <div className="flex space-x-4 mb-6">
        {["individual", "business", "b2b"].map(tab => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`px-4 py-2 rounded-md ${activeTab === tab ? "bg-blue-600 text-white" : "bg-gray-200 text-black"}`}
          >
            {tab === "individual" ? "Connectors" : tab === "business" ? "B2C Connectors" : "B2B Connectors"}
          </button>
        ))}
      </div>

      {activeTab === "individual" && (
        <div className="w-full max-w-xl bg-gray-50 p-6 rounded-2xl shadow-lg border border-gray-200">
          {!submitted ? (
            <form className="grid grid-cols-1 gap-4">
              <input name="fullName" value={formData.fullName} onChange={handleChange} placeholder="Full Name" className="border p-2 rounded-md" />
              <input name="profession" value={formData.profession} onChange={handleChange} placeholder="Profession" className="border p-2 rounded-md" />
              <input name="mobile" value={formData.mobile} onChange={handleChange} placeholder="Mobile Number" className="border p-2 rounded-md" />
              <input name="addressLine1" value={formData.addressLine1} onChange={handleChange} placeholder="Address Line 1" className="border p-2 rounded-md" />
              <input name="addressLine2" value={formData.addressLine2} onChange={handleChange} placeholder="Address Line 2" className="border p-2 rounded-md" />
              <input name="addressLine3" value={formData.addressLine3} onChange={handleChange} placeholder="Address Line 3" className="border p-2 rounded-md" />
              <div className="grid grid-cols-2 gap-4">
                <input name="city" value={formData.city} onChange={handleChange} placeholder="City" className="border p-2 rounded-md" />
                <input name="pincode" value={formData.pincode} onChange={handleChange} placeholder="Pincode" className="border p-2 rounded-md" />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <select name="country" value={formData.country} onChange={handleChange} className="border p-2 rounded-md">
                  <option value="">Select Country</option>
                  {countries.map(country => (
                    <option key={country} value={country}>{country}</option>
                  ))}
                </select>
                <select name="state" value={formData.state} onChange={handleChange} className="border p-2 rounded-md">
                  <option value="">Select State</option>
                  {states.map(state => (
                    <option key={state} value={state}>{state}</option>
                  ))}
                </select>
              </div>
              <input name="email" value={formData.email} onChange={handleChange} placeholder="Email ID" className="border p-2 rounded-md" />
              <input name="recoveryMobile" value={formData.recoveryMobile} onChange={handleChange} placeholder="Recovery Mobile No" className="border p-2 rounded-md" />
              <button type="button" onClick={handleSubmit} className="bg-blue-600 text-white py-2 rounded-md hover:bg-blue-700">
                Submit Individual Details
              </button>
            </form>
          ) : (
            <div className="grid gap-4 text-sm">
              <div className="p-4 bg-green-100 border border-green-300 rounded-md">
                <p><strong>Your CONNECTA ID:</strong> {connectaID}</p>
                <p><strong>Referral Link:</strong> connecta.co.in/join?ref={connectaID}</p>
                <div ref={qrRef} className="mt-2 flex justify-center">
                  <QRCode value={`https://connecta.co.in/join?ref=${connectaID}`} size={96} />
                </div>
                <div className="mt-2 flex space-x-2">
                  <button onClick={downloadQR} className="text-xs text-blue-600 underline">Download QR Code</button>
                  <button onClick={downloadReferralLink} className="text-xs text-blue-600 underline">Download Referral Link</button>
                </div>
              </div>
              <div>
                <label className="block font-medium mb-1">Upload Profile Image</label>
                <input type="file" accept="image/*" onChange={handleProfileImage} className="border p-2 rounded-md" />
              </div>
              <div className="mt-4 text-center font-semibold text-gray-700">Add Your Connectors</div>
              {!contactsAllowed ? (
                <button onClick={handleAllowContacts} className="bg-yellow-400 text-black py-2 rounded-md hover:bg-yellow-500">
                  Click Here to Open Contacts
                </button>
              ) : (
                <>
                  <button onClick={handleSendQR} className="bg-teal-600 text-white py-2 rounded-md hover:bg-teal-700">
                    Send QR Code by SMS / WhatsApp
                  </button>
                  {qrSent && (
                    <div className="mt-4 p-4 bg-blue-50 border border-blue-200 rounded-md text-sm text-gray-700">
                      <p>âœ… QR Code sent to:</p>
                      <ul className="list-disc pl-5 mt-2">
                        {selectedContacts.map((c, i) => (
                          <li key={i}>{c.name} - {c.mobile}</li>
                        ))}
                      </ul>
                    </div>
                  )}
                </>
              )}
            </div>
          )}
        </div>
      )}

      {activeTab === "business" && (
        <div className="text-gray-500 mt-10 italic">Business Onboarding Form Coming Soon...</div>
      )}
      {activeTab === "b2b" && (
        <div className="text-gray-500 mt-10 italic">B2B Onboarding Form Coming Soon...</div>
      )}
    </div>
  );
}

