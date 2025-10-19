import type { NextApiRequest, NextApiResponse } from "next";

const MSG91_BASE = "https://control.msg91.com/api/v5";
const isE164 = (m: string) => /^\+\d{6,15}$/.test(m);

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });
  try {
    const { mobile, otp } = req.body || {};
    if (!mobile || !otp) return res.status(400).json({ error: "Missing mobile or otp" });
    if (!isE164(mobile)) return res.status(400).json({ error: "Mobile must be E.164 (+<country><digits>)" });
    if (typeof otp !== "string" || !/^\d{4,8}$/.test(otp)) return res.status(400).json({ error: "Invalid OTP format" });

    const key = process.env.MSG91_API_KEY;
    if (!key) return res.status(500).json({ error: "MSG91 key not configured" });

    const r = await fetch(`${MSG91_BASE}/otp/verify`, {
      method: "POST",
      headers: { authkey: key!, "Content-Type": "application/json" },
      body: JSON.stringify({ mobile, otp }),
    });

    const data = await r.json().catch(() => ({}));
    if (!r.ok) return res.status(401).json({ error: data?.message || data?.error || `MSG91_HTTP_${r.status}` });

    return res.status(200).json({ ok: true });
  } catch (e: any) {
    return res.status(500).json({ error: e?.message || "OTP verify failed" });
  }
}
