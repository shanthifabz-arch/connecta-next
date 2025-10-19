// File: src/pages/api/validate-referral-mobile.ts
import type { NextApiRequest, NextApiResponse } from "next";
import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  try {
    const { referralCode, mobile, type } = req.body;

    if (!referralCode || !mobile || !type) {
      return res.status(400).json({ valid: false, error: "Missing input" });
    }

    if (type === "aa") {
      const { data, error } = await supabase
        .from("aa_connectors")
        .select("mobile")
        .eq("referralCode", referralCode)
        .eq("mobile", mobile)
        .single();

      if (error || !data) {
        console.warn("[AA] Mobile and referral code do not match:", error);
        return res.status(200).json({ valid: false });
      }

      return res.status(200).json({ valid: true });

    } else if (type === "child") {
      const { data: parent, error: referralError } = await supabase
        .from("connectors")
        .select("id")
        .eq("referralCode", referralCode)
        .single();

      if (referralError || !parent) {
        console.warn("[Child] Referral code not found:", referralError);
        return res.status(200).json({ valid: false });
      }

      const { data: existing, error: existingError } = await supabase
        .from("connectors")
        .select("id")
        .eq("mobile", mobile)
        .maybeSingle();

      if (existing) {
        console.warn("[Child] Mobile already exists:", mobile);
        return res.status(200).json({ valid: false });
      }

      return res.status(200).json({ valid: true });
    }

    // Fallback if type is invalid
    return res.status(400).json({ valid: false, error: "Invalid type" });

  } catch (err) {
    console.error("[API] Unexpected error:", err);
    return res.status(500).json({ valid: false, error: "Internal server error" });
  }
}

