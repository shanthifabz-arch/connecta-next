import type { NextApiRequest, NextApiResponse } from "next";
import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

const supabase = createClient(supabaseUrl, supabaseServiceKey);

type ResponseData = {
  valid: boolean;
  error?: string;
};

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse<ResponseData>
) {
  if (req.method !== "POST") {
    return res.status(405).json({ valid: false, error: "Method not allowed" });
  }

  let { referralCode, mobile } = req.body;
  console.log("[BE] Incoming request:", { referralCode, mobile });

  console.log("[API] Received referralCode:", referralCode);
  console.log("[API] Received mobile:", mobile);

  if (typeof referralCode !== "string" || typeof mobile !== "string") {
    console.log("[API] Invalid input types");
    return res.status(400).json({ valid: false, error: "Invalid input" });
  }

  referralCode = referralCode.trim();
  mobile = mobile.trim();

  try {

    const { data: debugRows, error: debugError } = await supabase
  .from("aa_connectors")
  .select("id, aa_joining_code, mobile")
  .eq("aa_joining_code", referralCode);

console.log("[BE] Rows found for referral code:", debugRows);
console.log("[BE] Debug error:", debugError);

    const { data, error } = await supabase
      .from("aa_connectors")
      .select("id")
      .eq("aa_joining_code", referralCode)
      .eq("mobile", mobile)
      .limit(1)
      .single();

    console.log("[API] Supabase query error:", error);
    console.log("[API] Supabase query data:", data);

    if (error || !data) {
      return res.status(200).json({ valid: false, error: "No matching connector" });
    }

    return res.status(200).json({ valid: true });
  } catch (err) {
    console.error("[API] Exception:", err);
    return res.status(500).json({ valid: false, error: "Server error" });
  }
}

