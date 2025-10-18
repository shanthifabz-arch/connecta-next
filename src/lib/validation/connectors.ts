import { z } from "zod";

export const e164 = z.string().regex(/^\+[1-9][0-9]{7,14}$/, "Use E.164 (e.g., +919876543210)");

export const addConnectorSchema = z.object({
  country: z.string().min(1),
  state: z.string().min(1),
  parent_ref: z.string().optional().nullable(),
  mobile: e164,
  fullname: z.string().min(1),
  email: z.string().email().optional().or(z.literal("").transform(() => undefined)),
  short: z
    .string()
    .max(14)
    .regex(/^[A-Za-z0-9]*$/, "A–Z0–9 only")
    .transform((s) => (s ? s.toUpperCase() : s))
    .optional(),
  recovery_e164: e164,
  extra: z.record(z.string(), z.unknown()).optional(),
}).refine((v) => v.mobile !== v.recovery_e164, {
  message: "Mobile number and recovery mobile number cannot be same",
  path: ["recovery_e164"],
});

export type AddConnectorInput = z.infer<typeof addConnectorSchema>;
