import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";

/**
 * POST /api/affiliates/order-webhook
 * Provider-tolerant payloads supported: cuelinks, impact, awin, generic
 * - Fields auto-detected for: external_order_id, amount_inr, status, click_ref
 * - If merchant_id not provided and you add (provider, provider_advertiser_id) to affiliates_merchants,
 *   we will try to resolve merchant_id automatically (see SQL note at bottom).
 */

type Payload = Record<string, any>;
type Normalized = {
  provider: string;
  externalOrderId: string;
  merchantId?: string;              // if not present, we may try DB lookup
  providerAdvertiserId?: string;    // optional hint for merchant lookup
  connectorGlobalId: string;
  amountInr: number;
  status: "approved" | "pending" | "cancelled";
  clickRef: string | null;
  rawPayload: any; // stored for audit
};

function toLowerStr(v: any): string {
  return String(v ?? "").toLowerCase();
}

function normalizeStatusGeneric(s: any): "approved" | "pending" | "cancelled" {
  const val = toLowerStr(s);
  if (["approved", "paid", "confirmed", "locked"].includes(val)) return "approved";
  if (["pending", "waiting", "open", "unpaid"].includes(val)) return "pending";
  if (["cancelled", "canceled", "declined", "rejected"].includes(val)) return "cancelled";
  return "approved";
}

/** -------- Provider mappers (non-destructive; very tolerant) -------- */
function mapCuelinks(body: Payload) {
  // Common Cuelinks webhook fields (varies by account):
  // order/txn: transaction_id | order_id
  // amount: sale_amount | sale_amount_in_inr | amount | order_amount
  // status: status
  // click ref: click_id | subid | sid | sid1 | subid1 | clickref
  const externalOrderId =
    body.external_order_id ??
    body.transaction_id ??
    body.order_id ??
    body.suborder_id ??
    null;

  const rawAmount =
    body.amount_inr ??
    body.sale_amount_in_inr ??
    body.sale_amount ??
    body.order_amount ??
    body.amount ??
    0;

  const providerAdvertiserId =
    body.advertiser_id ??
    body.merchant_id ??
    body.program_id ??
    null;

  const clickRef =
    body.click_ref ??
    body.click_id ??
    body.subid ??
    body.sid ??
    body.sid1 ??
    body.subid1 ??
    body.clickref ??
    null;

  return {
    externalOrderId,
    amountInr: Number(rawAmount || 0),
    status: normalizeStatusGeneric(body.status),
    clickRef: clickRef ?? null,
    providerAdvertiserId: providerAdvertiserId ? String(providerAdvertiserId) : undefined,
  };
}

function mapImpact(body: Payload) {
  // Typical Impact event/postback:
  // order id: OrderId | Oid | order_id | transaction_id
  // amount: Amount | OrderAmount | PayoutAmount | sale_amount
  // status: State (approved/pending/locked/rejected) → map 'locked' to approved
  // advertiser: AdvertiserId | CampaignId
  const externalOrderId =
    body.external_order_id ??
    body.OrderId ??
    body.Oid ??
    body.order_id ??
    body.transaction_id ??
    null;

  const rawAmount =
    body.amount_inr ??
    body.Amount ??
    body.OrderAmount ??
    body.sale_amount ??
    body.order_amount ??
    0;

  const state = body.State ?? body.status;
  const providerAdvertiserId = body.AdvertiserId ?? body.CampaignId ?? null;

  const clickRef =
    body.click_ref ??
    body.ClickId ??
    body.ClickRef ??
    body.subid ??
    body.sid ??
    body.clickref ??
    null;

  // Impact "locked" is effectively confirmed → approved
  const status = toLowerStr(state) === "locked" ? "approved" : normalizeStatusGeneric(state);

  return {
    externalOrderId,
    amountInr: Number(rawAmount || 0),
    status,
    clickRef: clickRef ?? null,
    providerAdvertiserId: providerAdvertiserId ? String(providerAdvertiserId) : undefined,
  };
}

function mapAwin(body: Payload) {
  // Awin validation webhooks:
  // order: orderRef | order_id | transaction_id
  // amount: sale_amount | amount | order_value
  // status: validation ('approved'|'pending'|'declined')
  // click ref: clickref | clickref2 | subid
  const externalOrderId =
    body.external_order_id ??
    body.orderRef ??
    body.order_id ??
    body.transaction_id ??
    null;

  const rawAmount =
    body.amount_inr ??
    body.sale_amount ??
    body.order_value ??
    body.amount ??
    0;

  const statusRaw = body.validation ?? body.status;
  const clickRef = body.click_ref ?? body.clickref ?? body.clickref2 ?? body.subid ?? null;

  const advertiserId =
    body.advertiserId ?? body.programId ?? body.advertiser_id ?? null;

  return {
    externalOrderId,
    amountInr: Number(rawAmount || 0),
    status: normalizeStatusGeneric(statusRaw),
    clickRef: clickRef ?? null,
    providerAdvertiserId: advertiserId ? String(advertiserId) : undefined,
  };
}

/** Generic mapper (used for unknown/others and also as fallback) */
function mapGeneric(body: Payload) {
  const externalOrderId =
    body.external_order_id ??
    body.order_id ??
    body.transaction_id ??
    body.transactionId ??
    body.orderId ??
    body.suborder_id ??
    body.subOrderId ??
    null;

  const rawAmount =
    body.amount_inr ??
    body.amount ??
    body.sale_amount ??
    body.order_amount ??
    body.commissionable_amount ??
    0;

  const clickRef =
    body.click_ref ??
    body.clickref ??
    body.click_id ??
    body.subid ??
    body.sid ??
    null;

  return {
    externalOrderId,
    amountInr: Number(rawAmount || 0),
    status: normalizeStatusGeneric(body.status),
    clickRef: clickRef ?? null,
    providerAdvertiserId: undefined,
  };
}

/** One normalizer for everything */
function normalizePayload(body: Payload): Normalized {
  const provider = toLowerStr(body.provider || "generic");

  let mapped:
    | ReturnType<typeof mapCuelinks>
    | ReturnType<typeof mapImpact>
    | ReturnType<typeof mapAwin>
    | ReturnType<typeof mapGeneric>;

  if (provider.includes("cuelinks")) mapped = mapCuelinks(body);
  else if (provider.includes("impact")) mapped = mapImpact(body);
  else if (provider.includes("awin")) mapped = mapAwin(body);
  else mapped = mapGeneric(body);

  return {
    provider,
    externalOrderId: mapped.externalOrderId ?? "",
    merchantId: body.merchant_id, // prefer explicit merchant_id if provided
    providerAdvertiserId: mapped.providerAdvertiserId,
    connectorGlobalId: String(body.connector_global_id || ""),
    amountInr: Number(mapped.amountInr || 0),
    status: mapped.status,
    clickRef: mapped.clickRef,
    rawPayload: body.raw_payload ?? body, // store full body for audit
  };
}

export async function POST(req: NextRequest) {
  try {
    const body = (await req.json()) as Payload;
    const n = normalizePayload(body);

    if (!n.externalOrderId) {
      return NextResponse.json(
        { ok: false, error: "external_order_id missing (accepts order_id/transaction_id/etc.)" },
        { status: 400 }
      );
    }
    if (!n.connectorGlobalId) {
      return NextResponse.json(
        { ok: false, error: "connector_global_id is required" },
        { status: 400 }
      );
    }

    const supabase = createClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.SUPABASE_SERVICE_ROLE_KEY! // server-only
    );

    // If merchant_id is missing, try resolving via (provider, provider_advertiser_id)
    let merchantId = n.merchantId;
    if (!merchantId && n.providerAdvertiserId) {
      const { data: m, error: mErr } = await supabase
        .from("affiliates_merchants")
        .select("id")
        .eq("provider", n.provider)
        .eq("provider_advertiser_id", n.providerAdvertiserId)
        .limit(1)
        .maybeSingle();

      if (mErr) {
        console.error("merchant lookup failed:", mErr);
      }
      merchantId = m?.id ?? undefined;
    }

    if (!merchantId) {
      return NextResponse.json(
        {
          ok: false,
          error:
            "merchant_id missing and could not auto-resolve. Pass merchant_id, or add (provider, provider_advertiser_id) on affiliates_merchants and re-post.",
          provider: n.provider,
          provider_advertiser_id: n.providerAdvertiserId ?? null,
        },
        { status: 400 }
      );
    }

    // Call your idempotent SQL
    const { data, error } = await supabase.rpc("record_affiliate_purchase", {
      p_provider: n.provider,
      p_external_order_id: n.externalOrderId,
      p_merchant_id: merchantId,
      p_connector_global_id: n.connectorGlobalId,
      p_amount_inr: n.amountInr,
      p_status: n.status,
      p_click_ref: n.clickRef,
      p_raw_payload: n.rawPayload,
    });

    if (error) {
      console.error("record_affiliate_purchase failed:", error);
      return NextResponse.json(
        {
          ok: false,
          error: error.message,
          external_order_id: n.externalOrderId,
          provider: n.provider,
        },
        { status: 400 }
      );
    }

    return NextResponse.json({
      ok: true,
      purchase_commission_id: data ?? null,
      external_order_id: n.externalOrderId,
      status: n.status,
    });
  } catch (e: any) {
    return NextResponse.json(
      { ok: false, error: e?.message || "Invalid payload" },
      { status: 400 }
    );
  }
}
