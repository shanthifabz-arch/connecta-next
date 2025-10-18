import type { NextApiRequest, NextApiResponse } from "next";

const MSG91_BASE = "https://control.msg91.com/api/v5";
const isE164 = (m: string) => /^\+\d{6,15}$/.test(m);

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });
  try {
    const { mobile } = req.body || {};
    if (!mobile || typeof mobile !== "string") return res.status(400).json({ error: "Missing mobile" });
    if (!isE164(mobile)) return res.status(400).json({ error: "Mobile must be E.164 (+<country><digits>)" });

    const key = process.env.MSG91_API_KEY;
    const templateId = process.env.MSG91_OTP_TEMPLATE_ID;
    const otpLength = Number(process.env.MSG91_OTP_LENGTH || 6);
    if (!key || !templateId) return res.status(500).json({ error: "MSG91 keys not configured" });

    const r = await fetch(`${MSG91_BASE}/otp`, {
      method: "POST",
      headers: { authkey: key!, "Content-Type": "application/json" },
      body: JSON.stringify({ mobile, template_id: templateId, otp_length: otpLength }),
    });

    const data = await r.json().catch(() => ({}));
    if (!r.ok) return res.status(502).json({ error: data?.message || data?.error || `MSG91_HTTP_${r.status}` });

    return res.status(200).json({ ok: true });
  } catch (e: any) {
    return res.status(500).json({ error: e?.message || "OTP send failed" });
  }
}
